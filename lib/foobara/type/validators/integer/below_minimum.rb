require "foobara/type/value_validator"
require "foobara/type/validator_error"

module Foobara
  class Type
    module Validators
      module Integer
        class BelowMinimum < Foobara::Type::ValueValidator
          class Error < Foobara::Type::ValidatorError
            class << self
              def context_schema
                {
                  path: :duck, # TODO: fix this up once there's an array type
                  attribute_name: :symbol,
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
            validator_data
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
