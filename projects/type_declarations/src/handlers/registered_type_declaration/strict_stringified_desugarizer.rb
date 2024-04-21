Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # type_symbol is basically just a flag that lets us know that type is fully qualified.
        # rather hacky but other potential workarounds seemed gnarlier
        class StrictStringifiedDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            # TODO: we shouldn't have to check if this is a hash. This means some other desugarizer is unnecessarily
            # processing a type declaration as if it were sugary. Find and fix that to speed this up a tiny bit.
            return false unless sugary_type_declaration.is_a?(::Hash) && TypeDeclarations.strict_stringified?

            !sugary_type_declaration.dig(:_desugarized, :type_absolutified)
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration = Util.symbolize_keys(sugary_type_declaration)
            type_symbol = sugary_type_declaration[:type]

            if type_symbol.is_a?(::String)
              type_symbol = type_symbol.to_sym
              sugary_type_declaration[:type] = type_symbol
            end

            desugarized = sugary_type_declaration[:_desugarized] || {}
            desugarized[:type_absolutified] = true
            sugary_type_declaration.merge(_desugarized: desugarized)
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
