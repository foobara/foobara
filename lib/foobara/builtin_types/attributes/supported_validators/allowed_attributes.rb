module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class AllowedAttributes < TypeDeclarations::Validator
          class UnexpectedAttributeError < Foobara::Value::DataError; end

          def error_halts_processing?
            true
          end

          def validation_errors(attributes_hash)
            unexpected_attributes = attributes_hash.keys - allowed_attributes

            unexpected_attributes.map do |unexpected_attribute_name|
              build_error(
                attributes_hash,
                message: "Unexpected attributes #{
                    unexpected_attribute_name
                  }. Expected only #{allowed_attributes}",
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
