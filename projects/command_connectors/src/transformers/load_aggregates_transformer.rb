module Foobara
  module CommandConnectors
    module Transformers
      class LoadAggregatesTransformer < Value::Transformer
        def transform(object)
          load_aggregates(object)
        end

        def load_aggregates(object)
          case object
          when Entity
            object.class.load_aggregate(object)
          when Array
            object.each do |element|
              load_aggregates(element)
            end
          when Hash
            object.each_key do |key|
              load_aggregates(key)
            end

            object.each_value do |value|
              load_aggregates(value)
            end
          end
        end
      end
    end
  end
end
