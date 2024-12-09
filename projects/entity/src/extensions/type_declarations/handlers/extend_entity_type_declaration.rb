module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendDetachedEntityTypeDeclaration
        def expected_type_symbol
          :entity
        end

        def priority
          super - 1
        end
      end
    end
  end
end
