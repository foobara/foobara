module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformers
        class Defaults < Value::Transformer
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module TypeDeclarationValidators
                class ValidAttributeNames < TypeDeclarations::TypeDeclarationValidator
                  class InvalidDefaultValueGivenError < Value::DataError
                    class << self
                      def context_type_declaration
                        {
                          invalid_key: :symbol,
                          valid_attribute_names: [:symbol],
                          defaults: :attributes
                        }
                      end

                      def fatal?
                        # Since there could be multiple bad defaults
                        true
                      end
                    end
                  end

                  def applicable?(strict_type_declaration)
                    defaults = strict_type_declaration[:defaults]

                    defaults.is_a?(::Hash) && Util.all_symbolic_keys?(defaults)
                  end

                  def validation_errors(strict_type_declaration)
                    defaults = strict_type_declaration[:defaults]

                    valid_attribute_names = strict_type_declaration[:element_type_declarations].keys

                    # TODO: this should be one error instead of multiple
                    defaults.keys.map do |key|
                      unless valid_attribute_names.include?(key)
                        build_error(
                          message: "#{key} is not a valid default key, expected one of #{valid_attribute_names}",
                          context: {
                            invalid_key: key,
                            valid_attribute_names:,
                            defaults:
                          }
                        )
                      end
                    end.compact
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
