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
          @input_type ||= Model::TypeBuilder.type_for(input_schema)
        end

        private

        def cast_inputs
          if input_schema.blank? && raw_inputs.blank?
            @inputs = {}
            return
          end

          outcome = input_type.process(raw_inputs)

          if outcome.success?
            @inputs = outcome.result
          else
            outcome.errors.each do |error|
              symbol = error.symbol
              message = error.message
              context = error.context

              add_input_error(attribute_name: error.attribute_name, symbol:, message:, context:)
            end
          end

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
