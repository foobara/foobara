module Foobara
  class Model
    class TypeBuilder
      module Validators
        module Attribute
          class ValidateRequiredAttributesPresent < Foobara::Type::ValueValidator
            attr_accessor :attribute_name, :default_value

            def initialize(attribute_name:)
              super()

              self.attribute_name = attribute_name
              self.default_value = default_value
            end

            def validation_errors(attributes_hash)
              unless attributes_hash.key?(attribute_name)
                Error.new(
                  symbol: error_symbol,
                  message: "Missing required attribute #{attribute_name}",
                  context: {
                    attribute_name:
                  }
                )
              end
            end

            def error_symbol
              @error_symbol ||= :"missing_#{attribute_name}"
            end
          end
        end
      end
    end
  end
end
