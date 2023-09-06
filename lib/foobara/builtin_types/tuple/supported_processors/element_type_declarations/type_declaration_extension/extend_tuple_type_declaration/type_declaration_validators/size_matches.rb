module Foobara
  module BuiltinTypes
    module Tuple
      module SupportedProcessors
        class ElementTypeDeclarations < TypeDeclarations::ElementProcessor
          module TypeDeclarationExtension
            module ExtendTupleTypeDeclaration
              module TypeDeclarationValidators
                class SizeMatches < TypeDeclarations::TypeDeclarationValidator
                  class IncorrectSizeError < Value::DataError
                    class << self
                      def context_type_declaration
                        {
                          expected_size: :integer,
                          actual_size: :integer,
                          value: :array
                        }
                      end
                    end
                  end

                  def applicable?(strict_type_declaration)
                    strict_type_declaration.key?(:size)
                  end

                  def validation_errors(strict_type_declaration)
                    size = strict_type_declaration[:size]
                    element_type_declarations = strict_type_declaration[:element_type_declarations]
                    element_type_declarations_size = element_type_declarations.size

                    if size != element_type_declarations_size
                      build_error(
                        message: "Expected tuple to have #{size} elements but it had #{element_type_declarations_size}",
                        context: {
                          expected_size: size,
                          actual_size: element_type_declarations_size,
                          value: strict_type_declaration
                        }
                      )
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
end
