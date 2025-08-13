Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        class ShortTypeNameDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false if TypeDeclarations.strict_stringified? || TypeDeclarations.strict?
            return false unless sugary_type_declaration.is_a?(::Hash)

            sugary_type_declaration = sugary_type_declaration.dup

            sugary_type_declaration = normalize_type(sugary_type_declaration)

            if sugary_type_declaration.key?(:type) &&
               !sugary_type_declaration.dig(:_desugarized, :type_absolutified)
              type_symbol = sugary_type_declaration[:type]

              (type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)) && type_registered?(type_symbol)
            end
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration = normalize_type(sugary_type_declaration)

            type_symbol = sugary_type_declaration[:type]
            type = lookup_type!(type_symbol)

            desugarized = sugary_type_declaration[:_desugarized] || {}
            desugarized[:type_absolutified] = true
            # Would be nice to use just the symbol as the type if it's registered but how do we know it
            # has been absolutified?
            sugary_type_declaration.merge(type: type.full_type_symbol, _desugarized: desugarized)
          end

          # TODO: clean this up in a different desugarizer so we don't have to think about it here
          def normalize_type(sugary_type_declaration)
            if sugary_type_declaration.key?("type") && !sugary_type_declaration.key?(:type)
              if Util.all_symbolizable_keys?(sugary_type_declaration)
                sugary_type_declaration = Util.symbolize_keys(sugary_type_declaration)
                type_symbol = sugary_type_declaration[:type]

                if type_symbol.is_a?(::String)
                  sugary_type_declaration[:type] = type_symbol.to_sym
                end
              end
            else
              sugary_type_declaration = sugary_type_declaration.dup
            end

            sugary_type_declaration
          end

          def priority
            Priority::FIRST + 2
          end
        end
      end
    end
  end
end
