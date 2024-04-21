Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # type_symbol is basically just a flag that lets us know that type is fully qualified.
        # rather hacky but other potential workarounds seemed gnarlier
        class StrictStringifiedDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless TypeDeclarations.strict_stringified?

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
            Priority::FIRST + 2
          end
        end
      end
    end
  end
end
