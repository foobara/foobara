module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class AttributesHandlerDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration[:type] == :model
          end

          def desugarize(sugary_type_declaration)
            handler = Namespace.current.handler_for_class(ExtendAttributesTypeDeclaration)
            attributes_type_declaration = sugary_type_declaration[:attributes_declaration]
            attributes_type = handler.process_value!(attributes_type_declaration)

            sugary_type_declaration.merge(
              attributes_declaration: attributes_type.declaration_data
            )
          end
        end
      end
    end
  end
end
