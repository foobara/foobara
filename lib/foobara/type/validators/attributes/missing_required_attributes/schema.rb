module Foobara
  module Type
    module Validators
      module Attributes
        class MissingRequiredAttributes < Value::Validator
          module Schema
            # TODO: Desugarizer should extend Caster
            module Desugarizer
              class << self
                def call(rawish_schema)
                  required_attributes = Array.wrap(rawish_schema[:required])

                  schemas = rawish_schema[:schemas]
                  schemas.each_pair do |attribute_name, attribute_schema|
                    if attribute_schema.is_a?(Hash) && attribute_schema.key?(:required)
                      required = attribute_schema[:required]
                      schemas[attribute_name] = attribute_schema.except(:required)

                      # TODO: is false a good no-op?
                      # Maybe make required true the default and add a :foo? convention/sugar?
                      required_attributes << attribute_name if required # required: false is a no-op as it's the default
                    end
                  end

                  rawish_schema[:required] = required_attributes unless required_attributes.empty?

                  Outcome.success(rawish_schema)
                end
              end
            end

            module SchemaValidator
              class << self
                def call(strict_schema_hash)
                  required = strict_schema_hash[:required]

                  return unless required.present?

                  if required.is_a?(Array) && Util.all_symbolic_elements?(required)
                    valid_attribute_names = strict_schema_hash[:schemas].keys

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
