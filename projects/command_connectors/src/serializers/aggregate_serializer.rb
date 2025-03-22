module Foobara
  module CommandConnectors
    module Serializers
      class AggregateSerializer < SuccessSerializer
        def serialize(object)
          case object
          when Entity
            # TODO: handle polymorphism? Would require iterating over the result type not the object!
            # Is there maybe prior art for this in the associations stuff?
            unless object.loaded? || object.built?
              object.class.load(object)
            end

            transform(object.attributes)
          when Model
            transform(object.attributes)
          when Array
            object.map { |element| transform(element) }
          when Hash
            object.to_h do |key, value|
              [transform(key), transform(value)]
            end
          else
            object
          end
        end
      end
    end
  end
end
