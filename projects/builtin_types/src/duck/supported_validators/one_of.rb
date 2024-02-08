module Foobara
  module BuiltinTypes
    module Duck
      module SupportedValidators
        class OneOf < TypeDeclarations::Validator
          class ValueNotValidError < Foobara::Value::DataError
            class << self
              def context_type_declaration
                {
                  value: :duck,
                  valid_values: [:duck]
                }
              end
            end
          end

          def valid_values
            declaration_data
          end

          def validation_errors(value)
            unless valid_values.include?(value)
              build_error
            end
          end

          def error_message(value)
            "#{value} must be one of #{valid_values} but is not."
          end

          def error_context(value)
            {
              value:,
              valid_values:
            }
          end
        end
      end
    end
  end
end
