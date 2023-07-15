module Foobara
  module Models
    class Schema
      attr_accessor :raw_schema, :strict_schema, :errors, :schema_has_been_validated

      def initialize(raw_schema)
        self.errors = []
        self.raw_schema = raw_schema
      end

      def type
        validate_schema unless schema_validated?

        strict_schema[:type]
      end

      def desugarize
        self.strict_schema = case raw_schema
                             when Symbol
                               { type: raw_schema }
                             when Hash
                               if !raw_schema.key?(:type) && !raw_schema.key?(:schemas) && raw_schema.keys.all? do |key|
                                    key.is_a?(Symbol)
                                  end
                                 { type: :attributes, schemas: raw_schema }
                               end
                             end

        self.strict_schema ||= raw_schema
      end

      def valid?
        schema_validation_errors.empty?
      end

      def schema_validation_errors
        validate_schema unless schema_validated?

        errors
      end

      def type_class
        Models.types[type]
      end

      delegate :can_cast?, :cast_from, :casting_errors, :validation_errors, to: :type_class

      def schema_validated?
        schema_has_been_validated
      end

      private

      def validate_schema
        self.schema_has_been_validated = true

        desugarize

        return errors if errors.present?

        Array.wrap(build_schema_validation_errors).each do |error|
          errors << error
        end

        errors
      end

      def build_schema_validation_errors
        if Models.types.key?(type)
          type_class.schema_validation_errors_for(strict_schema)
        else
          Error.new(
            :"unknown_type_#{type}",
            "Unknown type #{type}",
            raw_schema:,
            strict_schema:
          )
        end
      end
    end
  end
end
