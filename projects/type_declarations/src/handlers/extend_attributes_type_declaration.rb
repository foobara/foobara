module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = if sugary_type_declaration.strict?
                                         sugary_type_declaration
                                       else
                                         desugarize(TypeDeclaration.new(sugary_type_declaration))
                                       end

          if strictish_type_declaration.is_a?(::Hash) && strictish_type_declaration[:type] == :attributes
            unless strictish_type_declaration.equal?(sugary_type_declaration)
              sugary_type_declaration.assign(strictish_type_declaration)
            end

            true
          end
        end

        def priority
          Priority::LOW
        end
      end
    end
  end
end
