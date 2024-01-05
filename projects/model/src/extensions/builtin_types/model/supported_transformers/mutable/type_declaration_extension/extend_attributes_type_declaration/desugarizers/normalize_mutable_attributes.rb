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
                    if value.is_a?(::Hash)
                      mutable = value[:mutable]

                      mutable.is_a?(::Array) && mutable.any? { |v| !v.is_a?(::Symbol) }
                    end
                  end

                  def desugarize(rawish_type_declaration)
                    rawish_type_declaration[:mutable].map!(&:to_sym)
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
