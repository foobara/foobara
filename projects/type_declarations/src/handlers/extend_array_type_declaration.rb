module Foobara
  module TypeDeclarations
    module Handlers
      # Hmmmm... this inheritance feels backwards
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = if sugary_type_declaration.strict?
                                         sugary_type_declaration
                                       else
                                         desugarize(
                                           TypeDeclaration.new(sugary_type_declaration.declaration_data)
                                         )
                                       end

          if strictish_type_declaration.hash? && strictish_type_declaration[:type] == :array
            sugary_type_declaration.assign(strictish_type_declaration)
            true
          end
        end
      end
    end
  end
end
