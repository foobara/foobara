module Foobara
  module Enumerated
    class Values
      class BadNameType < ::StandardError; end
      class BadValueType < ::StandardError; end

      class << self
        def valid_value_type?(value)
          value.is_a?(String) || value.is_a?(Symbol) || value.nil?
        end

        def valid_name_type?(value)
          value.is_a?(String) || value.is_a?(Symbol)
        end

        def normalize_value(value)
          unless Values.valid_value_type?(value)
            # :nocov:
            raise BadValueType, "Expected nil, String, or Symbol, but got #{value} which is a #{value.class}"
            # :nocov:
          end

          value&.to_sym
        end

        def module_to_symbol_map(constants_module)
          symbol_map = {}

          constants_module.constants.each do |constant_name|
            constant_value = constants_module.const_get(constant_name)

            symbol_map[constant_name] = constant_value
          end

          symbol_map
        end

        def validate_symbol_map_types(symbol_map)
          symbol_map.each_pair do |name, value|
            unless valid_name_type?(name)
              # :nocov:
              raise BadNameType, "name is #{name} which is a #{name.class} but expected String, or Symbol"
              # :nocov:
            end

            unless valid_value_type?(value)
              # :nocov:
              raise BadValueType, "#{
                name
              } is #{value} which is a #{value.class} but expected nil, String, or Symbol"
              # :nocov:
            end
          end
        end

        def normalize_symbol_map(symbol_map)
          normalized = {}

          symbol_map.each_pair do |name, value|
            normalized[name.to_s.underscore.upcase.to_sym] = value && value.to_sym
          end

          normalized.freeze
        end
      end

      def initialize(*args)
        symbol_map = if args.size == 1
                       arg = args.first

                       case arg
                       when ::Module
                         Values.module_to_symbol_map(arg)
                       when ::Hash
                         arg
                       when ::Array
                         args = arg
                         nil
                       end
                     end

        unless symbol_map
          symbol_map = {}

          args.each do |value|
            symbol_map[value] = value
          end
        end

        Values.validate_symbol_map_types(symbol_map)

        @symbol_map = Values.normalize_symbol_map(symbol_map)
      end

      def all
        @symbol_map
      end

      def all_names
        @symbol_map.keys
      end

      def all_values
        @symbol_map.values
      end

      def method_missing(name)
        unless respond_to_missing?(name)
          # :nocov:
          super
          # :nocov:
        end

        @symbol_map[name]
      end

      def respond_to_missing?(name, _include_private = false)
        @symbol_map.key?(name)
      end
    end
  end
end
