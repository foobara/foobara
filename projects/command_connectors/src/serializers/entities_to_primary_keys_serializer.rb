require_relative "success_serializer"

module Foobara
  module CommandConnectors
    module Serializers
      class EntitiesToPrimaryKeysSerializer < SuccessSerializer
        def serialize(object)
          case object
          # What of DetachedEntity? I guess we should treat it as a model since we can't cast from primary key value to
          # a record?
          when Entity
            # TODO: handle polymorphism? Would require iterating over the result type not the object!
            # Is there maybe prior art for this in the associations stuff?
            object.primary_key
          when Model
            object.attributes
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
      end
    end
  end
end
