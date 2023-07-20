require "foobara/model/schema"

module Foobara
  class Model
    class AttributesSchema < Schema
      def valid_attribute_name?(attribute_name)
        valid_attribute_names.include?(attribute_name)
      end

      def valid_attribute_names
        strict_schema[:schemas].keys
      end

      def schema_validation_errors
        if type == :attributes
          super
        else
          Error.new(
            symbol: :not_attributes,
            message: "Expected attributes to be defined here but instead it was a schema for #{type}",
            context: {
              expected_type: :attributes,
              actual_type: type,
              raw_schema:,
              strict_schema:
            }
          )
        end
      end
    end
  end
end
