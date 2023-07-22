module Foobara
  class Command
    module Concerns
      module Inputs
        extend ActiveSupport::Concern

        attr_reader :inputs

        def method_missing(method_name, *args, &)
          if respond_to_missing_for_inputs?(method_name)
            inputs[method_name]
          else
            super
          end
        end

        def respond_to_missing?(method_name, private = false)
          respond_to_missing_for_inputs?(method_name, private) || super
        end

        def respond_to_missing_for_inputs?(method_name, _private = false)
          inputs&.key?(method_name)
        end

        def input_type
          @input_type ||= Model::SchemaTypeBuilder.for(input_schema)
        end

        private

        def cast_inputs
          if input_schema.blank? && raw_inputs.blank?
            @inputs = {}
            return
          end

          Array.wrap(input_type.casting_errors(raw_inputs)).each do |error|
            symbol = error.symbol
            message = error.message
            context = error.context

            input = context[:cast_to]

            add_input_error(input:, symbol:, message:, context:)
          end

          outcome = input_type.cast_from(raw_inputs)

          if outcome.success?
            @inputs = outcome.result
          end
        end

        def validate_inputs
          # TODO: check various validations like required, blank, etc
        end
      end
    end
  end
end
