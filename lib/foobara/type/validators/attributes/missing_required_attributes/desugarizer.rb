require "foobara/type/value_validator"

module Foobara
  class Type
    module Validators
      module Attributes
        class MissingRequiredAttributes < Foobara::Type::ValueValidator
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

                rawish_schema
              end
            end
          end
        end
      end
    end
  end
end
