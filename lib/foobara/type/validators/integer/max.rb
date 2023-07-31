require "foobara/type/value_validator"

module Foobara
  class Type
    module Validators
      module Integer
        class Max < Foobara::Type::ValueValidator
          class MaxExceededError < Foobara::Type::AttributeError
            class << self
              def symbol
                :max_exceeded
              end

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

          attr_accessor :max

          def initialize(max)
            super()

            self.max = max
          end

          def validation_errors(value)
            unless value <= max
              build_error(
                context: {
                  value:,
                  max:
                }
              )
            end
          end

          def error_class
            MaxExceededError
          end

          def error_message
            "Max exceeded. Should not have been larger than: #{max}"
          end
        end
      end
    end
  end
end