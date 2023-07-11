module Foobara
  module Models
    class Schema
      attr_accessor :raw_schema, :strict_schema, :errors, :schema_has_been_validated

      def initialize(raw_schema)
        self.errors = []
        self.raw_schema = raw_schema
      end

      def valid?
        validate_schema unless schema_validated?

        errors.empty?
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

      def validate_schema
        self.schema_has_been_validated = true

        desugarize

        return unless valid?

        if Models.types.key?(type)
          schema_errors = type_class.schema_validation_errors_for(strict_schema)

          if schema_errors.present?
            schema_errors.each { |error| errors << error }
          end
        else
          errors << "Unknown type: #{type}"
        end
      end

      def type_class
        Models.types[type]
      end

      def apply(object)
        casted_result = apply!(object)
        Outcome.success(casted_result)
      rescue Type::TypeConversionError => e
        Outcome.errors(e.errors)
      end

      def apply!(object)
        type_class.cast_from(object)
      end

      def schema_validated?
        schema_has_been_validated
      end
    end
  end
end
