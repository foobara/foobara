module Foobara
  module BuiltinTypes
    module Model
      module SupportedTransformers
        class Mutable < TypeDeclarations::Transformer
          module TypeDeclarationExtension
            module ExtendModelTypeDeclaration
              module Desugarizers
                class NormalizeMutableAttributes < TypeDeclarations::Desugarizer
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
                    binding.pry
                    rawish_type_declaration[:mutable] = Util.array(rawish_type_declaration[:mutable]).map!(&:to_sym)
                    rawish_type_declaration
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
