module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class AllowedAttributes < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module Desugarizers
                class SetAllowedAttributes < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    value.is_a?(::Hash) && value[:type] == :attributes
                  end

                  def desugarize(rawish_type_declaration)
                    rawish_type_declaration[:allowed_attributes] =
                      rawish_type_declaration[:element_type_declarations].keys

                    rawish_type_declaration
                  end

                  def priority
                    Priority::LOW
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
