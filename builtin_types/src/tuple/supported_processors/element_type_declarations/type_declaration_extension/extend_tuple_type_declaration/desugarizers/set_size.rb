module Foobara
  module BuiltinTypes
    module Tuple
      module SupportedProcessors
        class ElementTypeDeclarations < TypeDeclarations::ElementProcessor
          module TypeDeclarationExtension
            module ExtendTupleTypeDeclaration
              module Desugarizers
                class SetSize < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    if value.is_a?(::Hash)
                      value[:element_type_declarations].present? && value[:type] == :tuple && !value.key?(:size)
                    end
                  end

                  def desugarize(rawish_type_declaration)
                    rawish_type_declaration[:size] = rawish_type_declaration[:element_type_declarations].size
                    rawish_type_declaration
                  end

                  def priority
                    Priority::LOW
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
