module Foobara
  class Model
    class Schema
      # TODO: eliminate one of these error classes
      class InvalidSchemaError < Foobara::Error
      end

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

        def register_validator(type_symbol, validator_class)
          validators = @validators ||= {}

          for_type = validators[type_symbol] ||= {}

          for_type[validator_class.validator_symbol] = validator_class
        end

        def validators_for_type(type_symbol)
          @validators[type_symbol]
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

      attr_accessor :raw_schema, :schema_validation_errors
      attr_reader :strict_schema

      def initialize(raw_schema)
        raise ArgumentError, "must give a schema" unless raw_schema

        self.schema_validation_errors = []
        self.raw_schema = raw_schema

        @strict_schema = desugarize

        validate_schema!
      end

      delegate :type, :valid_schema_type?, to: :class

      def to_h
        { type: }
      end

      def has_errors?
        schema_validation_errors.present?
      end

      def valid?
        schema_validation_errors.empty?
      end

      def validate!
        unless valid?
          raise InvalidSchema, schema_validation_errors
        end
      end

      private

      def desugarize
        raise "Subclass responsibility"
      end

      def validate_schema
        return schema_validation_errors if @schema_validated

        build_schema_validation_errors

        @schema_validated = true

        schema_validation_errors
      end

      def validate_schema!
        validate_schema

        Outcome.raise!(schema_validation_errors)
      end

      def build_schema_validation_errors
        unless valid_schema_type?(type)
          schema_validation_errors << Error.new(
            symbol: :"unknown_type_#{type}",
            message: "Unknown type #{type}",
            context: {
              raw_schema:,
              strict_schema:
            }
          )
        end
      end

      register_validator(:integer, Type::Validators::Integer::MaxExceeded)
    end
  end
end
