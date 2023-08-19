module Foobara
  module BuiltinTypes
    module Number
      module SupportedValidators
        class BelowMinimum < TypeDeclarations::Validator
          class BelowMinimumError < Foobara::Value::AttributeError
            class << self
              def context_schema
                {
                  value: :number,
                  min: :number
                }
              end
            end
          end

          class << self
            def symbol
              # TODO: derive this symbol from the class instead...
              :min
            end

            def data_schema
              :number
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
