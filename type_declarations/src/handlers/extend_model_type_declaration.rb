Foobara::Util.require_project_file("type_declarations/handlers/extend_registered_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          if sugary_type_declaration.is_a?(::Hash)
            desugarize(sugary_type_declaration)[:type] == expected_type_symbol
          end
        end

        def expected_type_symbol
          :model
        end

        def priority
          Priority::MEDIUM
        end
      end
    end
  end
end
