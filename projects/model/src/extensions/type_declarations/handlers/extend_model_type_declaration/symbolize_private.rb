module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class SymbolizePrivate < TypeDeclarations::Desugarizer
          def applicable?(value)
            if value.is_a?(::Hash) && value.key?(:type) && value.key?(:attributes_declaration) && value.key?(:private)
              type_symbol = value[:type]

              if type_registered?(type_symbol)
                type = lookup_type!(type_symbol)
                type.extends?(BuiltinTypes[:model])
              end
            end
          end

          def desugarize(rawish_type_declaration)
            private = rawish_type_declaration[:private]

            if private.any? { |key| key.is_a?(::String) }
              rawish_type_declaration.merge(private: private.map(&:to_sym))
            else
              rawish_type_declaration
            end
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
