module Foobara
  module Common
    class ErrorKey
      # TODO: use this wherever it makes sense
      EMPTY_PATH = [].freeze

      class << self
        def to_s_type(key)
          unless key.is_a?(ErrorKey)
            key = parse(key)
          end

          key.to_s_type
        end

        def prepend_path(key, *)
          if key.is_a?(ErrorKey)
            key.prepend_path(*).to_s
          else
            key = parse(key)
            key.prepend_path!(*).to_s
          end
        end

        def prepend_runtime_path(key, prepend_part)
          if key.is_a?(ErrorKey)
            key.prepend_runtime_path(prepend_part).to_s
          else
            key = parse(key)
            key.prepend_runtime_path!(prepend_part).to_s
          end
        end

        # key contains.......
        # a:b:c:d.e.f.g.h
        # Then a, b, c is the runtime path and d is the category and e,f,g is the data path and h is the symbol
        def parse(key_string)
          *runtime_path, key_string = key_string.to_s.split(":")
          category, *path, symbol = key_string.split(".")

          new(category:, path:, symbol:, runtime_path:)
        end

        def to_h(key_string)
          parse(key_string).to_h
        end
      end

      attr_reader :category, :symbol, :path, :runtime_path

      # TODO: accept error_class instead of symbol/category??
      def initialize(symbol: nil, category: nil, path: EMPTY_PATH, runtime_path: EMPTY_PATH)
        self.category = symbolize(category)
        self.symbol = symbolize(symbol)
        self.path = symbolize(path)
        self.runtime_path = symbolize(runtime_path)
      end

      def symbol=(symbol)
        @symbol = symbolize(symbol)
      end

      def category=(category)
        @category = symbolize(category)
      end

      def path=(path)
        @path = symbolize_all(path)
      end

      def runtime_path=(runtime_path)
        @runtime_path = symbolize_all(runtime_path)
      end

      def prepend_path!(*prepend_parts)
        if prepend_parts.size == 1
          arg = prepend_parts.first

          if arg.is_a?(Array)
            prepend_parts = arg
          end
        end

        self.path = [*prepend_parts, *path]
        self
      end

      def prepend_path(*)
        dup.tap do |key|
          key.prepend_path!(*)
        end
      end

      def prepend_runtime_path!(prepend_parts)
        self.runtime_path = [*prepend_parts, *runtime_path]
        self
      end

      def prepend_runtime_path(prepend_parts)
        dup.tap do |key|
          key.runtime_path = [*prepend_parts, *runtime_path]
        end
      end

      INDEX_VALUE = /\A\d+\z/

      def to_s(convert_to_type: false)
        path = self.path

        if convert_to_type
          path = path.map do |path_part|
            path_part =~ INDEX_VALUE ? :"#" : path_part
          end
        end

        [
          *runtime_path,
          [category, *path, symbol].join(".")
        ].join(":")
      end

      def to_s_type
        to_s(convert_to_type: true)
      end

      def to_h
        {
          path:,
          runtime_path:,
          category:,
          symbol:
        }
      end

      private

      def symbolize_all(key_parts)
        symbolize(Array.wrap(key_parts))
      end

      def symbolize(key_parts)
        return nil if key_parts.nil?

        case key_parts
        when Array
          key_parts.map do |key_part|
            symbolize(key_part)
          end
        when Symbol, Integer
          key_parts
        when String
          if key_parts.blank?
            nil
          else
            key_parts.to_sym
          end
        else
          # :nocov:
          raise ArgumentError, "expected nil, a symbol, or a string, an integer, or an array of such values "
          # :nocov:
        end
      end
    end
  end
end
