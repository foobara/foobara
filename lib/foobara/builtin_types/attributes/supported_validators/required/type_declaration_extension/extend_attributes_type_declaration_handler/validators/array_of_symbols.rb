module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class Required < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module TypeDeclarationValidators
                class ArrayOfSymbols < TypeDeclarations::TypeDeclarationValidator
                  class InvalidRequiredAttributesValuesGivenError < Value::AttributeError
                    class << self
                      def message(_value)
                        "required should be an array of symbols"
                      end
                    end
                  end

                  def applicable?(strict_type_declaration)
                    strict_type_declaration.key?(:required)
                  end

                  def validation_errors(strict_type_declaration)
                    required = strict_type_declaration[:required]

                    unless required.is_a?(::Array) && Util.all_symbolic_elements?(required)
                      build_error(context: { required: })
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
