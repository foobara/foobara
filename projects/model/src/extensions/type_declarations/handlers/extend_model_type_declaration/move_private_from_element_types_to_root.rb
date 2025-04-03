module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class MovePrivateFromElementTypesToRoot < TypeDeclarations::Desugarizer
          def applicable?(value)
            if value.is_a?(::Hash) && value.key?(:type) && value.key?(:attributes_declaration)
              type_symbol = value[:type]

              if type_registered?(type_symbol)
                type = lookup_type!(type_symbol)
                type.extends?(BuiltinTypes[:model])
              end
            end
          end

          def desugarize(rawish_type_declaration)
            private = rawish_type_declaration[:private]
            private = private ? private.dup : []

            attributes_declaration = rawish_type_declaration[:attributes_declaration]
            element_type_declarations = attributes_declaration[:element_type_declarations]

            element_type_declarations.each_pair do |attribute_name, attribute_type_declaration|
              if attribute_type_declaration.is_a?(Hash) && attribute_type_declaration.key?(:private)
                is_private = attribute_type_declaration[:private]
                element_type_declarations[attribute_name] = attribute_type_declaration.except(:private)
                if is_private
                  private |= [attribute_name]
                end
              end
            end

            if private.empty?
              rawish_type_declaration.except(:private)
            else
              rawish_type_declaration.merge(private:)
            end
          end

          def priority
            Priority::MEDIUM + 1
          end
        end
      end
    end
  end
end
