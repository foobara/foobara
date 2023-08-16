require "foobara/type_declarations/desugarizer"
require "foobara/type_declarations/type_declaration_handler/extend_associative_array_type_declaration_handler"

module Foobara
  module TypeDeclarations
    class TypeDeclarationHandler < Value::Processor::Pipeline
      class ExtendAttributesTypeDeclarationHandler < ExtendAssociativeArrayTypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.is_a?(::Hash) && Util.all_symbolizable_keys?(sugary_type_declaration) &&
              (
                !strictish_type_declaration?(sugary_type_declaration) ||
                  Util.all_symbolizable_keys?(sugary_type_declaration.symbolize_keys[:element_types])
              )
          end

          def desugarize(attributes_hash)
            attributes_hash = attributes_hash.deep_dup

            attributes_hash.symbolize_keys!

            attributes_hash = if strictish_type_declaration?(attributes_hash)
                                attributes_hash
                              else
                                {
                                  type: :attributes,
                                  element_types: attributes_hash
                                }
                              end

            attributes_hash[:element_types].symbolize_keys!

            attributes_hash[:element_types].transform_values! do |element_type_declaration|
              handler = type_declaration_handler_registry.type_declaration_handler_for(element_type_declaration)
              handler.desugarize(element_type_declaration)
            end

            attributes_hash
          end

          private

          def strictish_type_declaration?(hash)
            keys = hash.keys.map(&:to_sym)
            keys.include?(:type) && keys.include?(:element_types)
          end
        end
      end
    end
  end
end
