module Foobara
  class Command
    module Concerns
      module Result
        extend ActiveSupport::Concern

        class CouldNotCastResult < StandardError; end

        def result_type
          @result_type ||= Model::TypeBuilder.for(result_schema)
        end

        private

        def cast_result_using_result_schema(result)
          return result  unless result_schema.present?

          casting_errors = Array.wrap(result_type.casting_errors(result))

          if casting_errors.present?
            message = casting_errors.map do |error|
              "#{error.message}\n#{error.context.inspect}"
            end.join("\n\n")

            raise CouldNotCastResult, message
          end

          result_type.cast_from!(result)
        end

        def validate_result_using_result_schema(result)
          return unless result_schema.present?

          Array.wrap(result_type.validation_errors(result)).each do |error|
            symbol = error.symbol
            message = error.message
            context = error.context

            add_runtime_error(symbol:, message:, context:)
          end
        end
      end
    end
  end
end
