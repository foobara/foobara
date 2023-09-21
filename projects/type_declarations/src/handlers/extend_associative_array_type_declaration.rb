Foobara::Util.require_project_file("type_declarations/handlers/extend_registered_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAssociativeArrayTypeDeclaration < ExtendRegisteredTypeDeclaration
        # TODO: do we really need this? Isn't this the default?
        def priority
          Priority::MEDIUM
        end
      end
    end
  end
end
