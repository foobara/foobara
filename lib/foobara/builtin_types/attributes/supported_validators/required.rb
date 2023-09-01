module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class Required < TypeDeclarations::Validator
          class MissingRequiredAttributeError < Foobara::Value::DataError
            class << self
              def context_type_declaration
                {
                  attribute_name: :symbol
                }
              end

              def fatal?
                true
              end
            end
          end

          def required_attribute_names
            required
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
