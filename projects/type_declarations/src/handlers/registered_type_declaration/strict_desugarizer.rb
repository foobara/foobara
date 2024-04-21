Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # type_symbol is basically just a flag that lets us know that type is fully qualified.
        # rather hacky but other potential workarounds seemed gnarlier
        class StrictDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(strict_type_declaration)
            # TODO: we shouldn't have to check if this is a hash. This means some other desugarizer is unnecessarily
            # processing a type declaration as if it were sugary. Find and fix that to speed this up a tiny bit.
            return false unless strict_type_declaration.is_a?(::Hash) && TypeDeclarations.strict?

            !strict_type_declaration.dig(:_desugarized, :type_absolutified)
          end

          def desugarize(strict_type_declaration)
            strict_type_declaration = Util.symbolize_keys(strict_type_declaration)
            desugarized = strict_type_declaration[:_desugarized] || {}
            desugarized[:type_absolutified] = true
            strict_type_declaration.merge(_desugarized: desugarized)
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
