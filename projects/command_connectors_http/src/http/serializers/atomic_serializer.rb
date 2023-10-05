module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Serializers
        class AtomicSerializer < Value::Transformer
          def transform(object)
            if object.is_a?(Model)
              if object.is_a?(Entity) && !object.loaded?
                # :nocov:
                raise "#{object} is not loaded so cannot serialize it"
                # :nocov:
              end

              object = object.attributes
            end

            deep_transform(object)
          end

          def deep_transform(object)
            case object
            when Entity
              # TODO: handle polymorphism? Would require iterating over the result type not the object!
              # Is there maybe prior art for this in the associations stuff?
              object.primary_key
            when Model
              object.attributes
            when Array
              object.map { |element| deep_transform(element) }
            when Hash
              object.to_h do |key, value|
                [deep_transform(key), deep_transform(value)]
              end
            else
              object
            end
          end
        end
      end
    end
  end
end
