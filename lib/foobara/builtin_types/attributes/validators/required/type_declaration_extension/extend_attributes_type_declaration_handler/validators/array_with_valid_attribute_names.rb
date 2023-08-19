module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class Required < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module TypeDeclarationValidators
                class ArrayWithValidAttributeNames < Value::Validator
                  # TODO: make this not necessary
                  def always_applicable?
                    true
                  end

                  def validation_errors(strict_type_declaration)
                    required = strict_type_declaration[:required]

                    return unless required.present?

                    if required.is_a?(::Array) && Util.all_symbolic_elements?(required)
                      valid_attribute_names = strict_type_declaration[:element_type_declarations].keys

                      required.map do |key|
                        unless valid_attribute_names.include?(key)
                          Error.new(
                            symbol: :invalid_required_attribute_name_given,
                            message: "#{key} is not a valid default key, expected one of #{valid_attribute_names}",
                            context: {
                              invalid_required_attribute_name: key,
                              valid_attribute_names:,
                              required:
                            }
                          )
                        end
                      end.compact.presence
                    else
                      Error.new(
                        symbol: :invalid_required_attributes_values_given,
                        message: "required should be an array of symbols",
                        context: {
                          required:
                        }
                      )
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
end
