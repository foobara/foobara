module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Serializers
        class AggregateSerializer < Value::Transformer
          def transform(object)
            case object
            when Entity
              # TODO: handle polymorphism? Would require iterating over the result type not the object!
              # Is there maybe prior art for this in the associations stuff?
              unless object.loaded?
                # :nocov:
                raise "#{object} is not loaded so cannot serialize it"
                # :nocov:
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
end
