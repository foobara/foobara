Foobara.require_project_file("type_declarations", "handlers/extend_registered_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAssociativeArrayTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = desugarize(sugary_type_declaration)

          strictish_type_declaration.is_a?(::Hash) && strictish_type_declaration[:type] == :associative_array
        end

        # TODO: do we really need this? Isn't this the default?
        def priority
          Priority::MEDIUM
        end
      end
    end
  end
end
