Foobara::Util.require_project_file(
  "type_declarations/handlers/extend_model_type_declaration/attributes_handler_desugarizer"
)

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendModelTypeDeclaration
        # TODO: need primary key type declaration validator!
        class AttributesHandlerDesugarizer < ExtendModelTypeDeclaration::AttributesHandlerDesugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration[:type] == expected_type_symbol
          end

          def expected_type_symbol
            :entity
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
