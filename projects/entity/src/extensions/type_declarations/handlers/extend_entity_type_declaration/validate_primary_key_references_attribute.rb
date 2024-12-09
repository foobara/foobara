module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendDetachedEntityTypeDeclaration
        class ValidatePrimaryKeyReferencesAttribute <
          ExtendDetachedEntityTypeDeclaration::ValidatePrimaryKeyReferencesAttribute
        end
      end
    end
  end
end
