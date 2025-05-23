module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        class ValidatePrimaryKeyReferencesAttribute < TypeDeclarations::TypeDeclarationValidator
          class InvalidPrimaryKeyError < TypeDeclarationError
            class << self
              def context_type_declaration
                {
                  allowed_primary_keys: [:symbol],
                  primary_key: :symbol
                }
              end
            end
          end

          def applicable?(strict_type_declaration)
            strict_type_declaration.key?(:primary_key) && strict_type_declaration[:primary_key].is_a?(::Symbol)
          end

          def validation_errors(strict_type_declaration)
            allowed_primary_keys = strict_type_declaration[:attributes_declaration][:element_type_declarations].keys

            primary_key = strict_type_declaration[:primary_key]
            unless allowed_primary_keys.include?(primary_key)
              build_error(
                message: "Invalid primary key. Expected #{primary_key} to be one of #{allowed_primary_keys}",
                context: { allowed_primary_keys:, primary_key: }
              )
            end
          end
        end
      end
    end
  end
end
