module Foobara
  class Model
    class TypeBuilder
      module Validators
        module Attribute
          class ValidateRequiredAttributesPresent < Foobara::Type::ValueValidator
            attr_accessor :attribute_name, :default_value, :path

            def initialize(attribute_name:, path:)
              super()

              self.path = path
              self.attribute_name = attribute_name
              self.default_value = default_value
            end

            def validation_errors(attributes_hash)
              unless attributes_hash.key?(attribute_name)
                AttributeError.new(
                  path:,
                  attribute_name:,
                  symbol: :missing_required_attribute,
                  message: "Missing required attribute #{attribute_name}",
                  context: {
                    attribute_name:
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
