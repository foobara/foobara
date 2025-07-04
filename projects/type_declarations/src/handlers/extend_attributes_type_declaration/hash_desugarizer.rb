Foobara.require_project_file("type_declarations", "desugarizer")
Foobara.require_project_file("type_declarations", "handlers/extend_associative_array_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.is_a?(::Hash)
            return false unless Util.all_symbolizable_keys?(sugary_type_declaration)

            sugary_type_declaration = Util.symbolize_keys(sugary_type_declaration)

            return true unless sugary_type_declaration.key?(:type)

            type_symbol = sugary_type_declaration[:type]

            if [:attributes, "attributes"].include?(type_symbol)
              sugary_type_declaration.key?(:element_type_declarations) &&
                Util.all_symbolizable_keys?(sugary_type_declaration[:element_type_declarations])
            elsif type_symbol.is_a?(::Symbol)
              # Why is this done?
              !type_registered?(type_symbol)
            end
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration = Util.deep_dup(sugary_type_declaration)

            Util.symbolize_keys!(sugary_type_declaration)

            unless strictish_type_declaration?(sugary_type_declaration)
              sugary_type_declaration = {
                type: :attributes,
                _desugarized: { type_absolutified: true },
                element_type_declarations: sugary_type_declaration
              }

            end

            Util.symbolize_keys!(sugary_type_declaration[:element_type_declarations])

            sugary_type_declaration
          end

          def priority
            Priority::HIGH
          end

          private

          def strictish_type_declaration?(hash)
            keys = hash.keys.map(&:to_sym)
            keys.include?(:type) && keys.include?(:element_type_declarations)
          end
        end
      end
    end
  end
end
