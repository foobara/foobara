module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendDetachedEntityTypeDeclaration
        class ValidatePrimaryKeyPresent < ExtendDetachedEntityTypeDeclaration::ValidatePrimaryKeyPresent
        end
      end
    end
  end
end
