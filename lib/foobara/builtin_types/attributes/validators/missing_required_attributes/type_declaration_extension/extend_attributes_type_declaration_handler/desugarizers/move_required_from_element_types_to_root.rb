module Foobara
  module BuiltinTypes
    module Attributes
      module Transformers
        class MissingRequiredAttributes < Value::Transformer
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclarationHandler
              module Desugarizers
                class MoveRequiredFromElementTypesToRoot < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    value.is_a?(::Hash) && value[:type] == :attributes
                  end

                  def desugarize(rawish_type_declaration)
                    required_attributes = ::Array.wrap(rawish_type_declaration[:required])

                    element_type_declarations = rawish_type_declaration[:element_type_declarations]

                    element_type_declarations.each_pair do |attribute_name, attribute_type_declaration|
                      if attribute_type_declaration.is_a?(::Hash) && attribute_type_declaration.key?(:required)
                        required = attribute_type_declaration[:required]

                        element_type_declarations[attribute_name] = attribute_type_declaration.except(:required)

                        # TODO: is false a good no-op?
                        # Maybe make required true the default and add a :foo? convention/sugar?
                        required_attributes << attribute_name if required # required: false is a no-op as it's the default
                      end
                    end

                    rawish_type_declaration[:required] = required_attributes unless required_attributes.empty?

                    rawish_type_declaration
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
