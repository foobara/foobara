Foobara.require_project_file("type_declarations", "desugarizer")
Foobara.require_project_file("type_declarations", "handlers/extend_associative_array_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false if sugary_type_declaration.strict?
            return false unless sugary_type_declaration.hash?

            type_symbol = sugary_type_declaration[:type]

            unless type_symbol
              return sugary_type_declaration.all_symbolizable_keys?
            end

            if type_symbol == :attributes
              sugary_type_declaration.key?(:element_type_declarations) &&
                Util.all_symbolizable_keys?(sugary_type_declaration[:element_type_declarations])
            elsif type_symbol.is_a?(::Symbol)
              # if the type isn't registered we will assume it's an attribute named type
              !type_registered?(type_symbol)
            end
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!

            unless strictish_type_declaration?(sugary_type_declaration)
              sugary_type_declaration.declaration_data = {
                type: :attributes,
                element_type_declarations: sugary_type_declaration.declaration_data
              }
              sugary_type_declaration.is_absolutified = true
              sugary_type_declaration.is_duped = true
            end

            sugary_type_declaration
          end

          def priority
            Priority::HIGH
          end

          private

          def strictish_type_declaration?(hash)
            if hash.key?(:type) || hash.key?("type")
              hash.key?(:element_type_declarations) || hash.key?("element_type_declarations")
            end
          end
        end
      end
    end
  end
end
