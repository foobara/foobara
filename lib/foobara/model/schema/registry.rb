module Foobara
  class Model
    class Schema
      class Registry
        class AlreadyRegisteredError < StandardError; end

        def initialize
          self.schemas = {}
        end

        def [](type_symbol)
          unless registered?(type_symbol)
            raise ArgumentError, "No schema registered for #{type_symbol.inspect}"
          end

          schemas[type_symbol]
        end

        def registered?(symbol_or_schema)
          if symbol_or_schema.is_a?(::Symbol)
            schemas.key?(symbol_or_schema)
          else
            schemas.values.include?(symbol_or_schema)
          end
        end

        def each_schema(&)
          schemas.values.each(&)
        end

        def register(schema)
          type_symbol = schema.type

          if registered?(type_symbol)
            raise AlreadyRegisteredError, "#{type_symbol.inspect} is already registered!"
          end

          schemas[type_symbol] = schema
        end

        private

        attr_accessor :schemas
      end
    end
  end
end
