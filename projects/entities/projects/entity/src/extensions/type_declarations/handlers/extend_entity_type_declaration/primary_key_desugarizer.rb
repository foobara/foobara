module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendDetachedEntityTypeDeclaration
        class PrimaryKeyDesugarizer < ExtendDetachedEntityTypeDeclaration::PrimaryKeyDesugarizer
        end
      end
    end
  end
end
