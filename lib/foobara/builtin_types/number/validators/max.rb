module Foobara
  module BuiltinTypes
    module Number
      module SupportedValidators
        class Max < TypeDeclarations::Validator
          class MaxExceededError < Foobara::Value::AttributeError
            class << self
              def context_type_declaration
                {
                  value: :number,
                  max: :number
                }
              end
            end
          end

          class << self
            def declaration_data_type_declaration
              :number
            end
          end

          def max
            declaration_data
          end

          def validation_errors(value)
            if value > max
              build_error(value)
            end
          end

          def error_message(value)
            "Max exceeded. #{value} is larger than #{max}"
          end

          def error_context(value)
            {
              value:,
              max:
            }
          end
        end
      end
    end
  end
end
