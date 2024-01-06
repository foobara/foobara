module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class NormalizeMutableAttributesDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(value)
            if value.is_a?(::Hash) && value.key?(:mutable) && value.key?(:type)
              mutable = value[:mutable]

              return false if [true, false].include?(mutable)

              if !mutable.is_a?(::Array) || (mutable.is_a?(::Array) && mutable.any? { |k| !k.is_a?(::Symbol) })
                type = type_for_declaration(value[:type])
                type.extends_symbol?(:model)
              end
            end
          end

          def desugarize(rawish_type_declaration)
            rawish_type_declaration.merge(
              mutable: Util.array(rawish_type_declaration[:mutable]).map!(&:to_sym)
            )
          end
        end
      end
    end
  end
end
