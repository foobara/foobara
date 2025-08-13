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

            type_symbol = if sugary_type_declaration.key?(:type)
                            sugary_type_declaration[:type]
                          elsif sugary_type_declaration.key?("type")
                            sugary_type_declaration["type"]
                          else
                            return false
                          end

            if type_symbol.is_a?(::String)
              type_symbol = type_symbol.to_sym
            end

            if :attributes == type_symbol
              if sugary_type_declaration.key?(:element_type_declarations)
                Util.all_symbolizable_keys?(sugary_type_declaration[:element_type_declarations])
              elsif sugary_type_declaration.key?("element_type_declarations")
                Util.all_symbolizable_keys?(sugary_type_declaration["element_type_declarations"])
              end
            elsif type_symbol.is_a?(::Symbol)
              # Why is this done?
              !type_registered?(type_symbol)
            end
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!

            unless sugary_type_declaration.deep_duped?
              sugary_type_declaration.declaration_data.transform_values! do |value|
                Util.deep_dup(value)
              end

              sugary_type_declaration.is_deep_duped = true
            end

            unless strictish_type_declaration?(sugary_type_declaration)
              sugary_type_declaration.declaration_data = {
                type: :attributes,
                element_type_declarations: sugary_type_declaration.declaration_data
              }
            end

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
