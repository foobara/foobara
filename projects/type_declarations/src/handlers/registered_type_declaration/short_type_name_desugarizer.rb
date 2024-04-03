Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # type_symbol is basically just a flag that lets us know that type is fully qualified.
        # rather hacky but other potential workarounds seemed gnarlier
        class ShortTypeNameDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            if sugary_type_declaration.is_a?(::Hash) && sugary_type_declaration.key?(:type) &&
               !sugary_type_declaration.dig(:_desugarized, :type_absolutified)
              type_symbol = sugary_type_declaration[:type]

              (type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)) && type_registered?(type_symbol)
            end
          end

          def desugarize(sugary_type_declaration)
            type_symbol = sugary_type_declaration[:type]
            type = lookup_type!(type_symbol)

            desugarized = sugary_type_declaration[:_desugarized] || {}
            desugarized[:type_absolutified] = true
            # TODO: just use the symbol and nothing else??
            # maybe confusing in languages with no distinction between symbol and string?
            sugary_type_declaration.merge(type: type.full_type_symbol, _desugarized: desugarized)
          end

          def priority
            Priority::FIRST + 1
          end
        end
      end
    end
  end
end
