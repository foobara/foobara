=begin
module Foobara
  class Model
    class Schema
      class Registry
        class AlreadyRegisteredError < StandardError; end
        class NotRegistered < StandardError; end

        class << self
          def global
            @global ||= new(fallback_registries: [])
          end
        end

        attr_accessor :fallback_registries

        def initialize(fallback_registries: [self.class.global])
          self.fallback_registries = fallback_registries
          self.schemas = {}
        end

        def [](type_symbol)
          if registered_locally?(type_symbol)
            schemas[type_symbol]
          else
            registry = registry_for(type_symbol)

            unless registry
              raise NotRegistered, "#{type_symbol} is not registered"
            end

            registry[type_symbol]
          end
        end

        def registry_for(symbol_or_schema)
          if registered_locally?(symbol_or_schema)
            self
          else
            fallback_registries.find do |registry|
              registry.registered_locally?(symbol_or_schema)
            end
          end
        end

        def registered_locally?(symbol_or_schema)
          if symbol_or_schema.is_a?(::Symbol)
            schemas.key?(symbol_or_schema)
          else
            schemas.values.include?(symbol_or_schema)
          end
        end

        def registered?(symbol_or_schema)
          registered_locally?(symbol_or_schema) || fallback_registries.any? do |registry|
            registry.registered?(symbol_or_schema)
          end
        end

        def each_schema(&)
          schemas.values.each(&)

          fallback_registries.each do |registry|
            registry.each_schema(&)
          end
          # all_schemas = [
          #   *schemas.values,
          #   *fallback_registries.map(&:schemas).map(&:values)
          # ].flatten
          #
          # all_schemas.each(&)
        end

        def register(schema)
          type_symbol = schema.type

          if registered?(type_symbol)
            raise AlreadyRegisteredError, "#{type_symbol.inspect} is already registered!"
          end

          schemas[type_symbol] = schema
        end

        def schema_for(sugary_schema)
          schema = nil

          if sugary_schema.is_a?(Hash) && sugary_schema.key?(:type)
            type = sugary_schema[:type]

            if registered?(type)
              schema = self[type]
            end
          end

          unless schema
            each_schema do |schema_class|
              if schema_class.can_handle?(sugary_schema)
                schema = schema_class
                break
              end
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

          schema.new(sugary_schema, schema_registry: self)
        end

        protected

        attr_accessor :schemas
      end
    end
  end
end
=end
