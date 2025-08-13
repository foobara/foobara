module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformers
        class Defaults < Value::Transformer
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module Desugarizers
                class SymbolizeDefaults < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    value.hash? && value[:type] == :attributes && value[:defaults]
                  end

                  def desugarize(rawish_type_declaration)
                    defaults = rawish_type_declaration[:defaults]

                    if defaults.any? { |key, _| key.is_a?(::String) }
                      rawish_type_declaration[:defaults] = defaults.transform_keys(&:to_sym)
                    end

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
