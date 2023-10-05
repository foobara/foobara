module Foobara
  module CommandConnectors
    module Transformers
      class LoadAggregatesPreCommitTransformer < Value::Transformer
        def applicable?(request)
          request.command.outcome.success?
        end

        def transform(request)
          load_aggregates(request.command.outcome.result)

          request
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
