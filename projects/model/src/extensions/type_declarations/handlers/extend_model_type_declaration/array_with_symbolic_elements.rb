module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ArrayWithSymbolicElements < TypeDeclarations::TypeDeclarationValidator
          class InvalidPrivateValuesGivenError < Value::DataError
            class << self
              def message
                "Private should be an array with symbolic elements"
              end
            end
          end

          def applicable?(strict_type_declaration)
            strict_type_declaration.is_a?(Hash) && strict_type_declaration.key?(:private)
          end

          def validation_errors(strict_type_declaration)
            private = strict_type_declaration[:private]

            unless private.is_a?(::Array) && Util.all_symbolic_elements?(private)
              build_error(context: { attribute_name: :private, value: private })
            end
          end
        end
      end
    end
  end
end
