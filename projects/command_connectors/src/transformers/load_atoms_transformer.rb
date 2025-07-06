module Foobara
  module CommandConnectors
    module Transformers
      class LoadAtomsPreCommitTransformer < Value::Transformer
        def applicable?(request)
          request.command.outcome.success?
        end

        def transform(request)
          load_atoms(request.command.outcome.result)

          request
        end

        def load_atoms(object)
          case object
          when Entity
            if object.persisted? && !object.loaded?
              object.class.load(object)
            end
          when Model
            load_atoms(object.attributes)
          when Array
            object.each do |element|
              load_atoms(element)
            end
          when Hash
            object.each_pair do |key, value|
              load_atoms(key)
              load_atoms(value)
            end
          end
        end
      end
    end
  end
end
