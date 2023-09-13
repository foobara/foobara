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
