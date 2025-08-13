module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class NormalizeMutableAttributesDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(value)
            if value.hash? && value.key?(:mutable) && value.key?(:type)
              mutable = value[:mutable]

              return false if mutable == true || mutable == false

              if !mutable.is_a?(::Array) || (mutable.is_a?(::Array) && mutable.any? { |k| !k.is_a?(::Symbol) })
                type = value.type
                unless type
                  type = type_for_declaration(value[:type])
                  value.type = type if type
                end

                type&.extends?(BuiltinTypes[:model])
              end
            end
          end

          def desugarize(rawish_type_declaration)
            rawish_type_declaration[:mutable] = Util.array(rawish_type_declaration[:mutable]).map!(&:to_sym)
            rawish_type_declaration
          end
        end
      end
    end
  end
end
