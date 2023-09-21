Foobara.require_file("type_declarations", "desugarizer")
Foobara.require_file("type_declarations", "handlers/extend_associative_array_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendTupleTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ArrayDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.is_a?(::Array) && sugary_type_declaration.size > 1
          end

          def desugarize(sugary_type_declaration)
            element_type_declarations = sugary_type_declaration.map do |element_type_declaration|
              handler = type_declaration_handler_for(element_type_declaration)

              handler.desugarize(element_type_declaration)
            end

            {
              type: :tuple,
              element_type_declarations:
            }
          end
        end
      end
    end
  end
end
