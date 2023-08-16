require "foobara/value/validator"
require "foobara/types/validator_error"

module Foobara
  module BuiltinTypes
    module Number
      module SupportedValidator
        class MaxExceeded < Foobara::Value::Validator
          # TODO: we should move this into a base class or something so we don't have to do it all over this project
          include TypeDeclarations::WithRegistries

          class Error < Foobara::Types::ValidatorError
            class << self
              def context_schema
                {
                  value: :number,
                  max: :number
                }
              end
            end
          end

          class << self
            def symbol
              :max
            end

            def data_schema
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
