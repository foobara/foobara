Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # type_symbol is basically just a flag that lets us know that type is fully qualified.
        # rather hacky but other potential workarounds seemed gnarlier
        class DesugarizerMetadataCleanupDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(strict_type_declaration)
            strict_type_declaration.is_a?(::Hash)
          end

          def desugarize(strict_type_declaration)
            strict_type_declaration.delete(:_desugarized)

            strict_type_declaration
          end

          def priority
            Priority::LOWEST + 100
          end
        end
      end
    end
  end
end
