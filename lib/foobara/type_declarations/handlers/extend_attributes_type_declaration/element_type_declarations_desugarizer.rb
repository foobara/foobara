require "foobara/type_declarations/desugarizer"
require "foobara/type_declarations/type_declaration_handler/extend_associative_array_type_declaration_handler"
require "foobara/type_declarations/type_declaration_handler/extend_attributes_type_declaration_handler/hash_desugarizer"

module Foobara
  module TypeDeclarations
    class TypeDeclarationHandler < Value::Processor::Pipeline
      class ExtendAttributesTypeDeclarationHandler < ExtendAssociativeArrayTypeDeclarationHandler
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
