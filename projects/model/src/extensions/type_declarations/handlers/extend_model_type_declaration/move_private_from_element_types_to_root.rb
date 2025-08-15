module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class MovePrivateFromElementTypesToRoot < TypeDeclarations::Desugarizer
          def applicable?(value)
            if value.hash? && value.key?(:type) && value.key?(:attributes_declaration)
              type = value.type || lookup_type(value[:type])

              if type
                if type.extends?(BuiltinTypes[:model])
                  value.type = type
                  true
                end
              end
            end
          end

          def desugarize(rawish_type_declaration)
            private = rawish_type_declaration[:private]

            if private.nil?
              private = []
            else
              unless rawish_type_declaration.deep_duped?
                private = private.dup
              end
            end

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
              rawish_type_declaration.delete(:private)
            else
              rawish_type_declaration[:private] = private
            end

            rawish_type_declaration
          end

          def priority
            Priority::MEDIUM + 1
          end
        end
      end
    end
  end
end
