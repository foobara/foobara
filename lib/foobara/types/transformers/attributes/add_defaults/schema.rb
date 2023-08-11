require "foobara/value/transformer"

module Foobara
  module Types
    module Transformers
      module Attributes
        class AddDefaults < Value::Transformer
          module Schema
            # TODO: should this be a value transformer??
            module Desugarizer
              class << self
                def call(rawish_schema)
                  defaults = rawish_schema[:defaults] || {}

                  schemas = rawish_schema[:schemas]

                  schemas.each_pair do |attribute_name, attribute_schema|
                    if attribute_schema.is_a?(Hash) && attribute_schema.key?(:default)
                      default = attribute_schema[:default]
                      schemas[attribute_name] = attribute_schema.except(:default)
                      defaults = defaults.merge(attribute_name => default)
                    end
                  end

                  rawish_schema[:defaults] = defaults unless defaults.empty?

                  Outcome.success(rawish_schema)
                end
              end
            end

            # TODO: should this be a value validator??
            module SchemaValidator
              class << self
                def call(strict_schema_hash)
                  defaults = strict_schema_hash[:defaults]

                  return unless defaults.present?

                  if defaults.is_a?(Hash) && Util.all_symbolic_keys?(defaults)
                    valid_attribute_names = strict_schema_hash[:schemas].keys

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
