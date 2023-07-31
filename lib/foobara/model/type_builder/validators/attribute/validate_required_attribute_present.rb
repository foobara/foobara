require "foobara/model/attribute_error"

module Foobara
  class Model
    class TypeBuilder
      module Validators
        module Attribute
          class ValidateRequiredAttributePresent < Foobara::Type::ValueValidator
            class MissingRequiredAttributeError < Foobara::AttributeError
              class << self
                def symbol
                  :missing_required_attribute
                end
              end
            end

            attr_accessor :attribute_name

            def initialize(attribute_name)
              super()

              self.attribute_name = attribute_name
            end

            def validation_errors(attributes_hash)
              build_error unless attributes_hash.key?(attribute_name)
            end

            def error_class
              MissingRequiredAttributeError
            end

            def error_path
              [attribute_name]
            end

            def error_message
              "Missing required attribute #{attribute_name}"
            end

            def error_context
              {
                attribute_name:
              }
            end
          end
        end
      end
    end
  end
end
