module Foobara
  module BuiltinTypes
    module Attributes
      module Transformers
        class UnexpectedAttributes < Value::Transformer
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclarationHandler
              module Desugarizers
                class SetAllowedAttributes < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    value.is_a?(::Hash) && value[:type] == :attributes
                  end

                  # TODO: maybe we need a cleaner way of handling this?
                  # TODO: feels like we could instead hook into element_type_declarations since that already has
                  # the allowed attributes??
                  def desugarize(rawish_type_declaration)
                    rawish_type_declaration[:unexpected_attributes] =
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
