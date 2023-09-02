module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class Required < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module TypeDeclarationValidators
                class ArrayWithValidAttributeNames < TypeDeclarations::TypeDeclarationValidator
                  class InvalidRequiredAttributeNameGivenError < Value::DataError
                    class << self
                      def context_type_declaration
                        {
                          invalid_required_attribute_name: :symbol,
                          valid_attribute_names: [:symbol],
                          required: [:symbol]
                        }
                      end
                    end
                  end

                  def applicable?(strict_type_declaration)
                    required = strict_type_declaration[:required]

                    required.is_a?(::Array) && Util.all_symbolic_elements?(required)
                  end

                  def validation_errors(strict_type_declaration)
                    required = strict_type_declaration[:required]

                    valid_attribute_names = strict_type_declaration[:element_type_declarations].keys

                    required.map do |key|
                      unless valid_attribute_names.include?(key)
                        build_error(
                          message: "#{key} is not a valid default key, expected one of #{valid_attribute_names}",
                          context: {
                            invalid_required_attribute_name: key,
                            valid_attribute_names:,
                            required:
                          }
                        )
                      end
                    end.compact.presence
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
