module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        def expected_type_symbol
          :detached_entity
        end

        def priority
          super - 1
        end
      end
    end
  end
end
