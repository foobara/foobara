module Foobara
  module CommandConnectors
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

          entities_to_primary_keys_serializer.serialize(object)
        end

        def entities_to_primary_keys_serializer
          @entities_to_primary_keys_serializer ||= EntitiesToPrimaryKeysSerializer.new(declaration_data)
        end
      end
    end
  end
end
