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
        def can_handle?(sugary_schema)
          sugary_schema == type
        end

        def register_schema(schema)
          Schema.global_schema_registry.register(schema)
        end

        def valid_schema_type?(symbol_or_schema, schema_registries: nil)
          [*schema_registries, Schema.global_schema_registry].uniq.any? do |registry|
            registry.registered?(symbol_or_schema)
          end
        end

        def type
          name.demodulize.gsub(/Schema$/, "").underscore.to_sym
        end

        # Problematic that this is on this class
        def register_validator(type_symbol, validator_class)
          validators = @validators ||= {}

          for_type = validators[type_symbol] ||= {}

          for_type[validator_class.validator_symbol] = validator_class
        end

        def validators_for_type(type_symbol)
          validators = if @validators.blank?
                         {}
                       else
                         @validators[type_symbol] || {}
                       end

          if self == Schema
            validators
          else
            validators.merge(superclass.validators_for_type(type_symbol))
          end
        end

        def for(sugary_schema, schema_registries: nil)
          schema_registries = [*schema_registries, Schema.global_schema_registry].compact.uniq

          return sugary_schema if sugary_schema.is_a?(Schema)

          schema = nil

          if sugary_schema.is_a?(Hash) && sugary_schema.key?(:type)
            type = sugary_schema[:type]

            schema = nil

            # Should we delete this method of finding a schema? Could prevent other schemas from claiming things with
            # type in it.
            schema_registries.each do |registry|
              if registry.registered?(type)
                schema = registry[type]
                break
              end
            end
          end

          unless schema
            schema_registries.each do |registry|
              registry.each_schema do |schema_class|
                if schema_class.can_handle?(sugary_schema)
                  schema = schema_class
                  break
                end
              end
              break if schema
            end
          end

          unless schema
            raise InvalidSchema, Error.new(
              symbol: :could_not_determine_schema_type,
              message: "Could not determine schema type for #{sugary_schema}",
              context: {
                raw_schema: sugary_schema
              }
            )
          end

          schema.new(sugary_schema, schema_registries:)
        end

        def global_schema_registry
          @global_schema_registry ||= Registry.new
        end
      end

      attr_accessor :raw_schema, :schema_validation_errors, :schema_registries
      attr_reader :strict_schema

      def initialize(raw_schema, schema_registries: nil)
        raise ArgumentError, "must give a schema" unless raw_schema

        self.schema_registries = schema_registries
        self.schema_validation_errors = []
        self.raw_schema = raw_schema

        @strict_schema = desugarize

        validate_schema!
      end

      delegate :type, :valid_schema_type?, :validators_for_type, to: :class

      def to_h
        h = { type: }

        Schema.validators_for_type(:integer).each_key do |validator_symbol|
          value = strict_schema[validator_symbol]
          h = h.merge(validator_symbol => value)
        end

        h
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
        if raw_schema == type
          { type: }
        else
          raw_schema
        end
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

      def build_schema_validation_errors(skip: nil)
        skip = Array.wrap(skip)

        unless valid_schema_type?(type, schema_registries:)
          schema_validation_errors << Error.new(
            symbol: :"unknown_type_#{type}",
            message: "Unknown type #{type}",
            context: {
              raw_schema:,
              strict_schema:
            }
          )
        end

        validators = self.class.validators_for_type(type) || {}
        allowed_keys = [*validators.keys, :type]

        strict_schema.each_pair do |key, value|
          next if key == :type
          next if skip.include?(key)

          if allowed_keys.include?(key)
            validator = validators[key]

            outcome = TypeBuilder.type_for(Schema.for(validator.data_schema, schema_registries:)).process(value,
                                                                                                          path: [key])

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
      end

      register_validator(:integer, Type::Validators::Integer::MaxExceeded)
      register_validator(:integer, Type::Validators::Integer::BelowMinimum)
    end
  end
end
