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
            if declaration_data[:detached_to_primary_key]
              object.primary_key
            else
              object.attributes
            end
          when Model
            object.attributes
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
      end
    end
  end
end
