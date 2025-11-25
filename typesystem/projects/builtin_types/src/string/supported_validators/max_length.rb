module Foobara
  module BuiltinTypes
    module String
      module SupportedValidators
        class MaxLength < TypeDeclarations::Validator
          class MaxLengthExceededError < Foobara::Value::DataError
            class << self
              def context_type_declaration
                {
                  value: :string,
                  max_length: :integer
                }
              end
            end
          end

          def validation_errors(string)
            if string.length > max_length
              build_error(string)
            end
          end

          def error_message(_value)
            "Max length exceeded. Cannot be longer than #{max_length}"
          end

          def error_context(value)
            {
              value:,
              max_length:
            }
          end
        end
      end
    end
  end
end
