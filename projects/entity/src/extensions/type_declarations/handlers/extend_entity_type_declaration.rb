Foobara.require_file(
  "entity",
  "extensions/type_declarations/handlers/extend_model_type_declaration"
)

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendModelTypeDeclaration
        def expected_type_symbol
          :entity
        end
      end
    end
  end
end
