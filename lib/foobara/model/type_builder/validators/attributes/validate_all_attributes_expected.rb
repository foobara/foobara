module Foobara
  class Model
    class TypeBuilder
      module Validators
        # TODO: move to Type project
        module Attribute
          class ValidateAllAttributesExpected < Foobara::Type::ValueValidator
            attr_accessor :allowed_attribute_names

            def initialize(allowed_attribute_names)
              super()
              self.allowed_attribute_names = allowed_attribute_names
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

            # We put the error on the parent object since we cannot anticipate in advance
            # what the unexpected attribute will be. This simplifies things elsewhere to consider the
            # attributes hash itself as invalid instead of the unexpected attribute as invalid
            # TODO: eliminate this is the default
            def error_path
              []
            end

            # TODO: this is here for compatibility elsewhere... can this be cleaned up somehow?
            # TODO: elimiinate this is the default
            def attribute_name
              nil
            end

            # TODO: eliminate
            def error_class
              Foobara::Type::UnexpectedAttributeError
            end
          end
        end
      end
    end
  end
end
