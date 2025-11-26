module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        class ValidatePrimaryKeyIsSymbol < TypeDeclarations::TypeDeclarationValidator
          class PrimaryKeyNotSymbolError < TypeDeclarationError
            class << self
              def context_type_declaration
                {
                  primary_key: :duck
                }
              end
            end
          end

          def applicable?(strict_type_declaration)
            strict_type_declaration.key?(:primary_key)
          end

          def validation_errors(strict_type_declaration)
            primary_key = strict_type_declaration[:primary_key]
            unless primary_key.is_a?(::Symbol)
              build_error(
                message: "Expected #{primary_key} to be a symbol but it was a #{primary_key.class}",
                context: {
                  primary_key:
                }
              )
            end
          end
        end
      end
    end
  end
end
