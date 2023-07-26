module Foobara
  class Command
    module Concerns
      module Inputs
        extend ActiveSupport::Concern

        class_methods do
          def input_type
            @input_type ||= Model::TypeBuilder.type_for(input_schema)
          end
        end

        attr_reader :inputs

        delegate :input_type, to: :class

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
          input_schema.schemas.key?(method_name)
        end

        private

        # TODO: change this name
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
              path = error.path
              attribute_name = error.attribute_name

              # TODO: why are we unpacking everything instead of just using AttributeError?
              add_input_error(attribute_name:, path:, symbol:, message:, context:)
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
