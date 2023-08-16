require "foobara/type_declarations/desugarizer"
require "foobara/type_declarations/type_declaration_handler/extend_associative_array_type_declaration_handler"

module Foobara
  module TypeDeclarations
    class TypeDeclarationHandler < Value::Processor::Pipeline
      class ExtendAttributesTypeDeclarationHandler < ExtendAssociativeArrayTypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.is_a?(::Hash)
            return false unless Util.all_symbolizable_keys?(sugary_type_declaration)

            !strictish_type_declaration?(sugary_type_declaration) ||
              Util.all_symbolizable_keys?(sugary_type_declaration.symbolize_keys[:element_type_declarations])
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration = sugary_type_declaration.deep_dup

            sugary_type_declaration.symbolize_keys!

            sugary_type_declaration = if strictish_type_declaration?(sugary_type_declaration)
                                        sugary_type_declaration
                                      else
                                        {
                                          type: :attributes,
                                          element_type_declarations: sugary_type_declaration
                                        }
                                      end

            sugary_type_declaration[:element_type_declarations].symbolize_keys!

            sugary_type_declaration[:element_type_declarations].transform_values! do |element_type_declaration|
              handler = type_declaration_handler_registry.type_declaration_handler_for(element_type_declaration)
              handler.desugarize(element_type_declaration)
            end

            sugary_type_declaration
          end

          private

          def strictish_type_declaration?(hash)
            keys = hash.keys.map(&:to_sym)
            keys.include?(:type) && keys.include?(:element_type_declarations)
          end
        end
      end
    end
  end
end
