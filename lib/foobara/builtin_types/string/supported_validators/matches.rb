module Foobara
  module BuiltinTypes
    module String
      module SupportedValidators
        class MatchesRegex < TypeDeclarations::Validator
          class DoesNotMatchError < Foobara::Value::DataError
            class << self
              def context_type_declaration
                {
                  value: :string,
                  regex: :duck # TODO: make a regex type??
                }
              end
            end
          end

          def regex
            declaration_data
          end

          def validation_errors(string)
            if string !~ regex
              build_error(string)
            end
          end

          def error_message(value)
            "#{value.inspect} did not match #{regex.inspect}"
          end

          def error_context(value)
            {
              value:,
              regex: regex.to_s
            }
          end
        end
      end
    end
  end
end
