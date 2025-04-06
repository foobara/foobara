module Foobara
  module CommandConnectors
    module Transformers
      # TODO: Should be a mutator instead
      class LoadDelegatedAttributesEntitiesPreCommitTransformer < Value::Transformer
        def applicable?(request)
          request.command.outcome.success?
        end

        def transform(request)
          result = request.command.outcome.result
          load_delegated_attribute_entities(result)

          request
        end

        def load_delegated_attribute_entities(object)
          case object
          when Entity
            object.class.delegates.each_key do |delegated_attribute_name|
              object.send(delegated_attribute_name)
            end
          when Array
            object.each do |element|
              load_delegated_attribute_entities(element)
            end
          when Hash
            object.each_key do |key|
              load_delegated_attribute_entities(key)
            end

            object.each_value do |value|
              load_delegated_attribute_entities(value)
            end
          end
        end
      end
    end
  end
end
