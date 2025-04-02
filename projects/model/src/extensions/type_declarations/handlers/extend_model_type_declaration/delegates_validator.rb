module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class DelegatesValidator < TypeDeclarations::TypeDeclarationValidator
          class InvalidDelegatesError < TypeDeclarationError
            context delegates: :duck
          end

          def applicable?(value)
            value.key?(:delegates)
          end

          def validation_errors(strict_type_declaration)
            delegates = strict_type_declaration[:delegates]

            unless delegates.is_a?(::Hash)
              return build_error(
                message: "delegates must be a hash",
                context: { delegates: }
              )
            end

            allowed_keys = %i[data_path writer]

            delegates.each_pair do |attribute_name, delegate_hash|
              invalid_keys = delegate_hash.keys - allowed_keys

              unless invalid_keys.empty?
                return build_error(
                  message: "delegates must only contain data_path and writer but contained " \
                           "#{invalid_keys} at #{attribute_name}",
                  context: { delegates: }
                )
              end
            end

            nil
          end
        end
      end
    end
  end
end
