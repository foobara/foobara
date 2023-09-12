module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class AttributesHandlerDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration[:type] == :model
          end

          def desugarize(sugary_type_declaration)
            handler = handler_for_class(ExtendAttributesTypeDeclaration)
            attributes_type_declaration = sugary_type_declaration[:attributes_declaration]

            sugary_type_declaration[:attributes_declaration] = handler.desugarize(attributes_type_declaration)

            sugary_type_declaration
          end
        end
      end
    end
  end
end
