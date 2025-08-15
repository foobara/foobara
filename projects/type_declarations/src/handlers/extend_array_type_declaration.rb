module Foobara
  module TypeDeclarations
    module Handlers
      # Hmmmm... this inheritance feels backwards
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = if sugary_type_declaration.strict?
                                         sugary_type_declaration
                                       else
                                         desugarize(sugary_type_declaration.clone)
                                       end

          if strictish_type_declaration.hash? && strictish_type_declaration[:type] == :array
            unless strictish_type_declaration.equal?(sugary_type_declaration)
              sugary_type_declaration.assign(strictish_type_declaration)
            end

            true
          end
        end
      end
    end
  end
end
