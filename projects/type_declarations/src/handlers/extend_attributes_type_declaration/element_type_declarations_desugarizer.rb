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
            sugary_type_declaration = sugary_type_declaration.dup

            sugary_type_declaration[:element_type_declarations] =
              sugary_type_declaration[:element_type_declarations].to_h do |attribute_name, element_type_declaration|
                if attribute_name != :_desugarized
                  element_type_declaration = if element_type_declaration.is_a?(Types::Type)
                                               element_type_declaration.reference_or_declaration_data
                                             else
                                               handler = type_declaration_handler_for(element_type_declaration)
                                               handler.desugarize(element_type_declaration)
                                             end
                end

                [attribute_name, element_type_declaration]
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
