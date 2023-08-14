=begin

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

      include Concerns::TypeBuilding
      include Concerns::ProcessorRegistries

      class << self
        def can_handle?(sugary_schema)
          sugary_schema == type
        end

        def valid_schema_type?(symbol_or_schema, schema_registry: Registry.global)
          schema_registry.registered?(symbol_or_schema)
        end

        def type
          name.demodulize.gsub(/Schema$/, "").underscore.to_sym
        end
      end

      attr_accessor :raw_schema, :schema_validation_errors, :schema_registry
      attr_reader :strict_schema

      def initialize(raw_schema, schema_registry: Schema::Registry.global)
        raise ArgumentError, "must give a schema" unless raw_schema

        self.schema_registry = schema_registry
        self.schema_validation_errors = []
        self.raw_schema = raw_schema

        @strict_schema = desugarize

        validate_schema!
      end

      delegate :type,
               :valid_schema_type?,
               to: :class

      def to_h
        strict_schema.dup
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

      def desugarize(raw_schema = @raw_schema)
        strict_schema_hash = if raw_schema == type
                               { type: }
                             else
                               raw_schema
                             end

        desugarizers.each do |desugarizer|
          outcome = desugarizer.call(strict_schema_hash)

          unless outcome.is_a?(Outcome)
            outcome = Outcome.success(outcome)
          end

          if outcome.success?
            strict_schema_hash = outcome.result
          else
            outcome.errors.each do |error|
              errors << error
            end

            break
          end
        end

        strict_schema_hash
      end

      def desugarizers
        processors.values.map do |processor|
          schema_module = Util.constant_value(processor, :Schema)

          if schema_module
            Util.constant_value(schema_module, :Desugarizer)
          end
        end.compact
      end

      def schema_validators
        processors.values.map do |processor|
          schema_module = Util.constant_value(processor, :Schema)

          if schema_module
            Util.constant_value(schema_module, :SchemaValidator)
          end
        end.compact
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

      def allowed_keys
        @allowed_keys ||= [*processors.keys, :type]
      end

      def build_schema_validation_errors
        unless valid_schema_type?(type, schema_registry:)
          schema_validation_errors << Error.new(
            symbol: :"unknown_type_#{type}",
            message: "Unknown type #{type}",
            context: {
              raw_schema:,
              strict_schema:
            }
          )
        end

        strict_schema.each_pair do |key, value|
          if allowed_keys.include?(key)
            processor = processors[key]

            next unless processor

            outcome = schema_registry.schema_for(processor.data_schema).to_type.process(value)

            unless outcome.success?
              outcome.each_error do |error|
                error.path = [key, *error.path]
              end
            end

            unless outcome.success?
              self.schema_validation_errors += outcome.errors
            end
          else
            schema_validation_errors << InvalidSchemaError.new(
              symbol: :invalid_schema_element,
              message: "Found #{key} but expected one of #{allowed_keys}"
            )
          end
        end

        schema_validators.each do |validator|
          break if schema_validation_errors.present?

          errors = Array.wrap(validator.call(to_h))

          errors.each do |error|
            schema_validation_errors << error
          end
        end
      end
    end
  end
end
=end
