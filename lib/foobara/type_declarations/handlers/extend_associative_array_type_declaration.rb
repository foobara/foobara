require "foobara/type_declarations/handlers/extend_registered_type_declaration"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAssociativeArrayTypeDeclaration < ExtendRegisteredTypeDeclaration
        def priority
          Priority::MEDIUM
        end
      end
    end
  end
end
