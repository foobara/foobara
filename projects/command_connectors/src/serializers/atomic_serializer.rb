module Foobara
  module CommandConnectors
    module Serializers
      # This seems to interpret "Atomic" as load the first entity you hit but not deeper entities.
      # Other interpretations it could have been:
      # 1) If top-level is an entity, load it and convert all nested entities to primary keys,
      #    otherwise, convert all entities to primary keys
      # 2) Once past the first model, all entities are cast to primary keys
      #
      # However, in the typescript-remote-command-generator, the logic is a little different...
      # There, AtomModelGenerator always uses primary keys for all entities.
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
