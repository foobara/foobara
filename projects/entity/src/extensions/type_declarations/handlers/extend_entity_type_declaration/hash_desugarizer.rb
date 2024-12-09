module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendDetachedEntityTypeDeclaration
        class HashDesugarizer < ExtendDetachedEntityTypeDeclaration::HashDesugarizer
          def expected_type_symbol
            :entity
          end
        end
      end
    end
  end
end
