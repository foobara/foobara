module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class Required < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module Desugarizers
                class AlphabetizeRequired < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    value.is_a?(::Hash) && value[:type] == :attributes &&
                      value.key?(:required) && value[:required].size > 1
                  end

                  def desugarize(rawish_type_declaration)
                    required = rawish_type_declaration[:required]

                    sorted_required = required.sort

                    if sorted_required == required
                      rawish_type_declaration
                    else
                      rawish_type_declaration.merge(required: sorted_required)
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
      end
    end
  end
end
