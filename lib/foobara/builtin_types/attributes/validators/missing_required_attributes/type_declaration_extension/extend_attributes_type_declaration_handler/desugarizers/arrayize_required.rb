module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidator
        class MissingRequiredAttributes < Foobara::Value::Validator
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclarationHandler
              module Desugarizers
                class ArrayizeRequired < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    value.is_a?(::Hash) && value[:type] == :attributes &&
                      value.key?(:required) && !value[:required].is_a?(::Array)
                  end

                  def desugarize(rawish_type_declaration)
                    rawish_type_declaration[:required] = ::Array.wrap(rawish_type_declaration[:required])

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
