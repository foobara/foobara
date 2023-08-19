module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class Required < TypeDeclarations::Validator
          class Error < Foobara::Value::AttributeError
            class << self
              def context_type_declaration
                {
                  attribute_name: :symbol
                }
              end

              # TODO: use the name of the error class instead
              def symbol
                :missing_required_attribute
              end
            end
          end

          class << self
            def data_schema
              :duck # TODO: expand when we have support for an array of symbols
            end
          end

          def required_attribute_names
            required
          end

          def error_halts_processing?
            true
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
