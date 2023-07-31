require "foobara/type/attribute_error"

module Foobara
  class Model
    class TypeBuilder
      module Validators
        module Attribute
          class MissingRequiredAttribute < Foobara::Type::ValueValidator
            class Error < Foobara::Type::ValidatorError; end

            attr_accessor :attribute_name

            def initialize(attribute_name)
              super()
              self.attribute_name = attribute_name
            end

            def validation_errors(attributes_hash)
              build_error(attributes_hash) unless attributes_hash.key?(attribute_name)
            end

            def error_message(_value)
              "Missing required attribute #{attribute_name}"
            end

            def error_context(_value)
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
