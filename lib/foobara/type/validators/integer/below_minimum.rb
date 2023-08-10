require "foobara/type/validator_error"

module Foobara
  module Type
    module Validators
      module Integer
        class BelowMinimum < Foobara::Value::Validator
          class Error < Foobara::Type::ValidatorError
            class << self
              def context_schema
                {
                  value: :integer,
                  min: :integer
                }
              end
            end
          end

          class << self
            def symbol
              :min
            end

            def data_schema
              :integer
            end
          end

          def min
            declaration_data
          end

          def validation_errors(value)
            if value < min
              build_error(value)
            end
          end

          def error_message(value)
            "Below minimum allowed. #{value} is less than #{min}"
          end

          def error_context(value)
            {
              value:,
              min:
            }
          end
        end
      end
    end
  end
end
