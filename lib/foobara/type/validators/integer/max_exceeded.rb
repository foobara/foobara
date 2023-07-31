require "foobara/type/value_validator"
require "foobara/type/validator_error"

module Foobara
  class Type
    module Validators
      module Integer
        class MaxExceeded < Foobara::Type::ValueValidator
          class Error < Foobara::Type::ValidatorError
            class << self
              def context_schema
                {
                  path: :duck, # TODO: fix this up once there's an array type
                  attribute_name: :symbol,
                  value: :integer,
                  max: :integer
                }
              end
            end
          end

          class << self
            def validator_symbol
              :max
            end
          end

          attr_accessor :max

          def initialize(max)
            super()

            self.max = max
          end

          def validation_errors(value)
            unless value <= max
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
