module Foobara
  module CommandConnectors
    module Serializers
      class AtomicSerializer < SuccessSerializer
        def serialize(object)
          case object
          when DetachedEntity
            if object.is_a?(Entity) && !object.built? && !object.loaded?
              object.class.load(object)
            end

            entities_to_primary_keys_serializer.serialize(object.attributes_with_delegates)
          when Model
            serialize(object.attributes_with_delegates)
          when Array
            object.map { |element| serialize(element) }
          when Hash
            object.to_h do |key, value|
              [serialize(key), serialize(value)]
            end
          else
            object
          end
        end

        def entities_to_primary_keys_serializer
          @entities_to_primary_keys_serializer ||= EntitiesToPrimaryKeysSerializer.new(declaration_data)
        end
      end
    end
  end
end
