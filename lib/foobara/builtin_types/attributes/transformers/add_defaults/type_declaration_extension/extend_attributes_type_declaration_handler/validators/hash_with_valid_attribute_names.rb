module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformer
        class AddDefaults < Value::Transformer
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclarationHandler
              module TypeDeclarationValidators
                class HashWithValidAttributeNames < Value::Validator
                  def always_applicable?
                    true
                  end

                  def validation_errors(strict_type_declaration)
                    defaults = strict_type_declaration[:defaults]

                    return unless defaults.present?

                    if defaults.is_a?(Hash) && Util.all_symbolic_keys?(defaults)
                      valid_attribute_names = strict_type_declaration[:element_type_declarations].keys

                      defaults.keys.map do |key|
                        unless valid_attribute_names.include?(key)
                          Error.new(
                            symbol: :invalid_default_value_given,
                            message: "#{key} is not a valid default key, expected one of #{valid_attribute_names}",
                            context: {
                              invalid_key: key,
                              valid_attribute_names:,
                              defaults:
                            }
                          )
                        end
                      end.compact
                    else
                      Error.new(
                        symbol: :invalid_default_values_given,
                        message: "defaults should be a hash with symbolic keys",
                        context: {
                          defaults:
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
