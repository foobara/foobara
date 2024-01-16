Foobara.require_project_file("type_declarations", "desugarizer")
Foobara.require_project_file("type_declarations", "handlers/extend_associative_array_type_declaration")
Foobara.require_project_file("type_declarations", "handlers/extend_attributes_type_declaration/hash_desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ElementTypeDeclarationsDesugarizer < HashDesugarizer
          def desugarize(sugary_type_declaration)
            sugary_type_declaration[:element_type_declarations].transform_values! do |element_type_declaration|
              handler = type_declaration_handler_for(element_type_declaration)
              handler.desugarize(element_type_declaration)
            end

            sugary_type_declaration
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
