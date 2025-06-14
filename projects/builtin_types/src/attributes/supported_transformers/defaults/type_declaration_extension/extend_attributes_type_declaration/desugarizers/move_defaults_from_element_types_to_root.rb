module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformers
        class Defaults < Value::Transformer
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module Desugarizers
                class MoveDefaultsFromElementTypesToRoot < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    value.is_a?(::Hash) && value[:type] == :attributes && value.key?(:element_type_declarations)
                  end

                  def desugarize(rawish_type_declaration)
                    defaults = rawish_type_declaration[:defaults]
                    defaults = defaults ? defaults.dup : {}

                    element_type_declarations = rawish_type_declaration[:element_type_declarations]

                    element_type_declarations.each_pair do |attribute_name, attribute_type_declaration|
                      if attribute_type_declaration.is_a?(Hash) && attribute_type_declaration.key?(:default)
                        default = attribute_type_declaration[:default]
                        element_type_declarations[attribute_name] = attribute_type_declaration.except(:default)
                        defaults.merge!(attribute_name => default)
                      end
                    end

                    if defaults.empty?
                      rawish_type_declaration.delete(:defaults)
                    else
                      rawish_type_declaration[:defaults] = defaults
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
