module Foobara
  module CommandConnectors
    module Serializers
      # TODO: put an entity-free version of this in model_plumbing!
      # TODO: can't this just inherit from Serializer??
      # TODO: shouldn't this be a transformer? It's not really serializing anything
      #       just preparing the data for serialization.
      class AggregateSerializer < SuccessSerializer
        def serialize(object)
          case object
          when Entity
            # TODO: handle polymorphism? Would require iterating over the result type not the object!
            # Is there maybe prior art for this in the associations stuff?
            unless object.loaded? || object.built?
              object.class.load(object)
            end

            transform(object.attributes_with_delegates)
          when Model
            transform(object.attributes_with_delegates)
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
