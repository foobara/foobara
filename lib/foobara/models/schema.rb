module Foobara
  module Models
    class Schema
      attr_accessor :raw_schema, :strict_schema, :errors, :has_been_validated

      def initialize(raw_schema)
        self.errors = []
        self.raw_schema = raw_schema
      end

      def valid?
        validate unless validated?

        errors.empty?
      end

      def type
        validate unless validated?

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

      def validate
        self.has_been_validated = true

        desugarize

        return unless valid?

        unless Models.types.key?(type)
          errors << "Unknown type: #{type}"
        end

        if type == :attributes
          schemas = strict_schema[:schemas]

          if schemas.blank?
            errors << "attributes type must have a schemas entry"
          elsif schemas.keys.any? { |key| !key.is_a?(Symbol) }
            errors << "Attributes must have all symbolic keys"
          end
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

      def validated?
        has_been_validated
      end
    end
  end
end
