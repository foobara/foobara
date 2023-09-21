module Foobara
  module BuiltinTypes
    module Array
      module SupportedValidators
        class Size < TypeDeclarations::Validator
          class IncorrectTupleSizeError < Value::DataError
            class << self
              def context_type_declaration
                {
                  expected_size: :integer,
                  actual_size: :integer,
                  value: :array
                }
              end
            end
          end

          def expected_size
            size
          end

          def validation_errors(array)
            if array.size != expected_size
              build_error(array)
            end
          end

          def error_message(array)
            "Invalid tuple size. #{array.inspect} should have had #{expected_size} elements but had #{array.size}."
          end

          def error_context(array)
            {
              expected_size:,
              actual_size: array.size,
              value: array
            }
          end
        end
      end
    end
  end
end
