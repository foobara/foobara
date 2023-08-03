module Foobara
  class Command
    module Concerns
      module Inputs
        extend ActiveSupport::Concern

        class_methods do
          def inputs_type
            @inputs_type ||= input_schema.to_type
          end
        end

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
          input_schema&.schemas&.key?(method_name)
        end

        delegate :inputs_type, to: :class

        def cast_and_validate_inputs
          if input_schema.blank? && raw_inputs.blank?
            @inputs = {}
            return
          end

          outcome = inputs_type.process(raw_inputs)

          if outcome.success?
            @inputs = outcome.result
          else
            outcome.errors.each do |error|
              if error.is_a?(Type::AttributeError)
                add_input_error(error)
              else
                # TODO: raise a real error
                raise "wtf"
              end
            end
          end

          if outcome.success?
            @inputs = outcome.result
          end
        end
      end
    end
  end
end
