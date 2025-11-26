module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        class ValidatePrimaryKeyPresent < TypeDeclarations::TypeDeclarationValidator
          # TODO: seems like maybe we could actually check against types now...
          # like make a type for primary_key: :symbol ??
          class MissingPrimaryKeyError < TypeDeclarationError; end

          def validation_errors(strict_type_declaration)
            unless strict_type_declaration.key?(:primary_key)
              build_error
            end
          end

          def error_message(_value)
            "Missing required :primary_key to state which attribute is the primary key"
          end

          def error_context(_value)
            {}
          end
        end
      end
    end
  end
end
