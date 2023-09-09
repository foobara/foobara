module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          if sugary_type_declaration.is_a?(::Hash)
            desugarize(sugary_type_declaration)[:type] == :model
          end
        end

        def priority
          Priority::MEDIUM
        end
      end
    end
  end
end
