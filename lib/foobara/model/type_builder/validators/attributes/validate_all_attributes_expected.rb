module Foobara
  class Model
    class TypeBuilder
      module Validators
        module Attribute
          class ValidateAllAttributesExpected < Foobara::Type::ValueValidator
            attr_accessor :allowed_attribute_names

            def initialize(allowed_attribute_names)
              super()

              self.allowed_attribute_names = allowed_attribute_names
            end

            def validation_errors(attributes_hash)
              unexpected_attributes = attributes_hash.keys - allowed_attribute_names

              unexpected_attributes.map do |unexpected_attribute_name|
                UnexpectedAttributeError.new(
                  attribute_name: unexpected_attribute_name,
                  symbol: :unexpected_attributes,
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
end
