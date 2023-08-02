require "foobara/type/value_validator"
require "foobara/type/validator_error"

module Foobara
  class Type
    module Validators
      module Attributes
        class MissingRequiredAttributes < Foobara::Type::ValueValidator
          class Error < Foobara::Type::ValidatorError
            class << self
              def context_schema
                {
                  attribute_name: :symbol
                }
              end

              def symbol
                :missing_required_attribute
              end
            end
          end

          class << self
            def symbol
              :required
            end
          end

          attr_accessor :required_attribute_names

          def initialize(required_attribute_names)
            super()
            self.required_attribute_names = required_attribute_names
          end

          def validation_errors(attributes_hash)
            required_attribute_names.map do |required_attribute_name|
              unless attributes_hash.key?(required_attribute_name)
                build_error(
                  message: "Missing required attribute #{required_attribute_name}",
                  context: { attribute_name: required_attribute_name }
                )
              end
            end.compact
          end
        end
      end
    end
  end
end
