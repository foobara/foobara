require_relative "success_serializer"

module Foobara
  module CommandConnectors
    module Serializers
      class EntitiesToPrimaryKeysSerializer < SuccessSerializer
        def serialize(object)
          case object
          when Entity
            # TODO: handle polymorphism? Would require iterating over the result type not the object!
            # Is there maybe prior art for this in the associations stuff?
            object.primary_key
          when DetachedEntity
            if detached_to_primary_key?
              object.primary_key
            else
              object.attributes_with_delegates
            end
          when Model
            object.attributes_with_delegates
          when ::Array
            object.map { |element| serialize(element) }
          when ::Hash
            object.to_h do |key, value|
              [serialize(key), serialize(value)]
            end
          else
            object
          end
        end

        def detached_to_primary_key?
          return true unless declaration_data.is_a?(::Hash)
          return true unless declaration_data.key?(:detached_to_primary_key)

          declaration_data[:detached_to_primary_key]
        end
      end
    end
  end
end
