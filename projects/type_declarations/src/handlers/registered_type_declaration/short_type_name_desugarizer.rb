Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        class ShortTypeNameDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            binding.pry if sugary_type_declaration.hash? && sugary_type_declaration["type"] == "string"

            return false if sugary_type_declaration.strict? || sugary_type_declaration.strict_stringified?
            return false unless sugary_type_declaration.hash?
            return false if sugary_type_declaration.absolutified?

            type_symbol = if sugary_type_declaration.key?(:type)
                            sugary_type_declaration[:type]
                          elsif sugary_type_declaration.key?("type")
                            sugary_type_declaration["type"]
                          end

            if type_symbol
              (type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)) && type_registered?(type_symbol)
            end
          end

          def desugarize(sugary_type_declaration)
            binding.pry if sugary_type_declaration.hash? && sugary_type_declaration["type"] == "string"

            sugary_type_declaration.symbolize_keys!

            type = lookup_type!(sugary_type_declaration[:type])

            # TODO: just use the symbol and nothing else??
            # maybe confusing in languages with no distinction between symbol and string?
            sugary_type_declaration[:type] = type.full_type_symbol
            sugary_type_declaration.is_absolutified = true

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
