require "foobara/value/validator"
require "foobara/types/validator_error"

module Foobara
  module Types
    module Validators
      module Integer
        class MaxExceeded < Foobara::Value::Validator
          class Error < Foobara::Types::ValidatorError
            class << self
              def context_schema
                {
                  value: :integer,
                  max: :integer
                }
              end
            end
          end

          class << self
            def symbol
              :max
            end

            def data_schema
              :integer
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
