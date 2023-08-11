module Foobara
  module Types
    module Validators
      module Attributes
        class UnexpectedAttributes < Value::Validator
          class Error < Foobara::Value::AttributeError
            class << self
              def symbol
                :unexpected_attribute
              end
            end
          end

          class << self
            # TODO: better symbol would be "allowed_attributes"
            def symbol
              :unexpected_attributes
            end

            def data_schema
              :duck # TODO: expand when we have support for an array of symbols
            end
          end

          def allowed_attribute_names
            declaration_data
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
