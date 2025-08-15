module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class SymbolizePrivate < TypeDeclarations::Desugarizer
          def applicable?(value)
            if value.hash? && value.key?(:type) && value.key?(:attributes_declaration) && value.key?(:private)

              type = value.type || lookup_type(value[:type])

              if type
                value.type = type
                type.extends?(BuiltinTypes[:model])
              end
            end
          end

          def desugarize(rawish_type_declaration)
            private = rawish_type_declaration[:private]

            if private.any? { |key| key.is_a?(::String) }
              rawish_type_declaration[:private] = private.map(&:to_sym)
            end

            rawish_type_declaration
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
