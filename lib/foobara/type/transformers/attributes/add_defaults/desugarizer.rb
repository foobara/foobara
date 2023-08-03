require "foobara/type/value_transformer"

module Foobara
  class Type
    module Transformers
      module Attributes
        class AddDefaults < Foobara::Type::ValueTransformer
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
        end
      end
    end
  end
end
