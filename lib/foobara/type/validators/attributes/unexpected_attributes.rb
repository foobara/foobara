module Foobara
  class Type
    module Validators
      module Attributes
        class UnexpectedAttributes < Foobara::Type::ValueValidator
          class Error < Foobara::Type::ValidatorError
            class << self
              def symbol
                :unexpected_attribute
              end
            end
          end

          class << self
            def symbol
              :unexpected_attributes
            end

            def always_applies?
              true
            end
          end

          def allowed_attribute_names
            strict_schema_hash[:schemas].keys
          end

          def error_halts_processing?
            true
          end

          def validation_errors(attributes_hash)
            unexpected_attributes = attributes_hash.keys - allowed_attribute_names

            unexpected_attributes.map do |unexpected_attribute_name|
              build_error(
                attributes_hash,
                message: "Unexpected attributes #{
                    unexpected_attribute_name
                  }. Expected only #{allowed_attribute_names}",
                context: {
                  attribute_name: unexpected_attribute_name,
                  value: attributes_hash[unexpected_attribute_name]
                }
              )
            end
          end
        end
      end
    end
  end
end
