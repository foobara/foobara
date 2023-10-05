module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Serializers
        class AtomicSerializer < SuccessSerializer
          def serialize(object)
            if object.is_a?(Model)
              if object.is_a?(Entity) && !object.loaded?
                # :nocov:
                raise "#{object} is not loaded so cannot serialize it"
                # :nocov:
              end

              object = object.attributes
            end

            deep_serialize(object)
          end

          def deep_serialize(object)
            case object
            when Entity
              # TODO: handle polymorphism? Would require iterating over the result type not the object!
              # Is there maybe prior art for this in the associations stuff?
              object.primary_key
            when Model
              object.attributes
            when Array
              object.map { |element| deep_serialize(element) }
            when Hash
              object.to_h do |key, value|
                [deep_serialize(key), deep_serialize(value)]
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
