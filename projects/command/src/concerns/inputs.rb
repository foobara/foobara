module Foobara
  class Command
    module Concerns
      module Inputs
        include Concern

        attr_reader :inputs

        def method_missing(method_name, *args, &)
          if respond_to_missing_for_inputs?(method_name)
            inputs[method_name]
          else
            # :nocov:
            super
            # :nocov:
          end
        end

        def respond_to_missing?(method_name, private = false)
          respond_to_missing_for_inputs?(method_name, private) || super
        end

        def respond_to_missing_for_inputs?(method_name, _private = false)
          inputs_type.element_types.key?(method_name)
        end

        delegate :inputs_type, to: :class

        def cast_and_validate_inputs
          if inputs_type.blank? && raw_inputs.blank?
            @inputs = {}
            return
          end

          outcome = inputs_type.runner(raw_inputs).process_value

          if outcome.success?
            @inputs = outcome.result
          else
            outcome.errors.each do |error|
              if error.is_a?(Value::DataError)
                add_input_error(error)
              else
                # TODO: raise a real error
                # :nocov:
                raise "wtf"
                # :nocov:
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
