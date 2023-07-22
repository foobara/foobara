module Foobara
  class Model
    class Schema
      class InvalidSchema < StandardError
        attr_accessor :schema_validation_errors

        def initialize(schema_validation_errors)
          self.schema_validation_errors = Array.wrap(schema_validation_errors)

          super(self.schema_validation_errors.map(&:message).join(", "))
        end
      end

      class << self
        def register_schema(schema)
          schema_classes << schema
        end

        def valid_schema_type?(symbol)
          Schema.schema_classes.any? { |klass| klass.type == symbol }
        end

        def schema_classes
          @schema_classes ||= []
        end

        def type
          name.demodulize.gsub(/Schema$/, "").underscore.to_sym
        end

        def for(sugary_schema)
          return sugary_schema if sugary_schema.is_a?(Schema)

          schema_type = nil

          if sugary_schema.is_a?(Hash) && sugary_schema.key?(:type)
            type = sugary_schema[:type]

            schema_type = schema_classes.find { |klass| klass.type == type }
          end

          schema_type ||= schema_classes.find { |klass| klass.can_handle?(sugary_schema) }

          unless schema_type
            raise InvalidSchema, Error.new(
              symbol: :could_not_determine_schema_type,
              message: "Could not determine schema type for #{sugary_schema}",
              context: {
                raw_schema: sugary_schema
              }
            )
          end

          schema_type.new(sugary_schema)
        end
      end

      attr_accessor :raw_schema, :errors, :schema_has_been_validated
      attr_reader :strict_schema

      def initialize(raw_schema)
        raise "must give a schema" unless raw_schema

        self.errors = []
        self.raw_schema = raw_schema
        @strict_schema = desugarize
      end

      delegate :type, :valid_schema_type?, to: :class

      def to_h
        strict_schema
      end

      def valid?
        schema_validation_errors.empty?
      end

      def schema_validation_errors
        validate_schema unless schema_validated?

        errors
      end

      def validate!
        unless valid?
          raise InvalidSchema, schema_validation_errors
        end
      end

      # TODO: maybe this can live elsewhere higher up?
      def type_instance
        case type
        when :attributes
          AttributesTypeBuilder.new(self)
        else
          PrimitiveTypeBuilder.new(type)
        end.to_type
      end

      def schema_validated?
        schema_has_been_validated
      end

      private

      def desugarize
        raise "Subclass responsibility"
      end

      def validate_schema
        self.schema_has_been_validated = true

        return errors if errors.present?

        Array.wrap(build_schema_validation_errors).each do |error|
          errors << error
        end

        errors
      end

      def build_schema_validation_errors
        unless valid_schema_type?(type)
          Error.new(
            symbol: :"unknown_type_#{type}",
            message: "Unknown type #{type}",
            context: {
              raw_schema:,
              strict_schema:
            }
          )
        end
      end
    end
  end
end
