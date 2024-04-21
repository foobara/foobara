Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # type_symbol is basically just a flag that lets us know that type is fully qualified.
        # rather hacky but other potential workarounds seemed gnarlier
        class StrictDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(strict_type_declaration)
            return false unless TypeDeclarations.strict?

            !strict_type_declaration.dig(:_desugarized, :type_absolutified)
          end

          def desugarize(strict_type_declaration)
            strict_type_declaration = Util.symbolize_keys(strict_type_declaration)
            desugarized = strict_type_declaration[:_desugarized] || {}
            desugarized[:type_absolutified] = true
            strict_type_declaration.merge(_desugarized: desugarized)
          end

          def priority
            Priority::FIRST + 2
          end
        end
      end
    end
  end
end
