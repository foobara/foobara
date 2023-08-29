module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformers
        class Defaults < Value::Transformer
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module TypeDeclarationValidators
                class HashWithSymbolicKeys < TypeDeclarations::TypeDeclarationValidator
                  class InvalidDefaultValuesGivenError < Value::DataError
                    class << self
                      def message(_value)
                        "defaults should be a hash with symbolic keys"
                      end
                    end
                  end

                  def applicable?(strict_type_declaration)
                    strict_type_declaration.is_a?(Hash) && strict_type_declaration.key?(:defaults)
                  end

                  def validation_errors(strict_type_declaration)
                    defaults = strict_type_declaration[:defaults]

                    unless defaults.is_a?(Hash) && Util.all_symbolic_keys?(defaults)
                      build_error(context: { defaults: })
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
