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
            # simplecov:disable
            raise BadValueType, "Expected nil, String, or Symbol, but got #{value} which is a #{value.class}"
            # simplecov:enable
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
              # simplecov:disable
              raise BadNameType, "name is #{name} which is a #{name.class} but expected String, or Symbol"
              # simplecov:enable
            end

            unless valid_value_type?(value)
              # simplecov:disable
              raise BadValueType, "#{
                name
              } is #{value} which is a #{value.class} but expected nil, String, or Symbol"
              # simplecov:enable
            end
          end
        end

        def normalize_symbol_map(symbol_map)
          normalized = {}

          symbol_map.each_pair do |name, value|
            normalized[Util.constantify(name).gsub(/[:\/]/, "_").to_sym] = value&.to_sym
          end

          normalized.freeze
        end
      end

      def initialize(*args)
        if args.empty?
          # simplecov:disable
          raise ArgumentError, "Expected Module, Hash, or Array"
        # simplecov:enable
        elsif args.size > 1
          initialize(args)
        else
          symbol_map = args[0]

          case symbol_map
          when ::Hash
            Values.validate_symbol_map_types(symbol_map)

            @symbol_map = Values.normalize_symbol_map(symbol_map)
          when ::Module
            initialize(Values.module_to_symbol_map(symbol_map))
          when ::Array
            initialize(symbol_map.to_h { |name| [name, name] })
          else
            # simplecov:disable
            raise ArgumentError, "Expected Module, Hash, or Array"
            # simplecov:enable
          end
        end
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
          # simplecov:disable
          super
          # simplecov:enable
        end

        @symbol_map[name]
      end

      def respond_to_missing?(name, _include_private = false)
        @symbol_map.key?(name)
      end

      def value?(value)
        @symbol_map.values.include?(value.to_sym)
      end

      def make_module
        mod = Module.new
        enumerated = self

        [:all, :all_names, :all_values, :value?].each do |method_name|
          mod.singleton_class.define_method method_name do |*args, **opts, &block|
            enumerated.__send__(method_name, *args, **opts, &block)
          end
        end

        @symbol_map.each_pair do |name, value|
          mod.const_set(name, value)
        end

        mod
      end
    end
  end
end
