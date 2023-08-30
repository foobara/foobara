module Foobara
  module Common
    class Error < StandardError
      # TODO: rename :path to data_path
      attr_accessor :error_key, :message, :context

      class << self
        def symbol
          name.demodulize.underscore.gsub(/_error$/, "").to_sym
        end

        def path
          ErrorKey::EMPTY_PATH
        end

        def runtime_path
          ErrorKey::EMPTY_PATH
        end

        def category
          nil
        end

        def message
          nil
        end

        def context
          nil
        end

        def parse_key(key)
          ErrorKey.parse(key)
        end
      end

      delegate :runtime_path,
               :runtime_path=,
               :category,
               :category=,
               :path,
               :path=,
               :symbol,
               :symbol=,
               to: :error_key

      # TODO: seems like we should not allow the symbol to vary within instances of a class
      def initialize(
        path: self.class.path,
        runtime_path: self.class.runtime_path,
        category: self.class.category,
        message: self.class.message,
        symbol: self.class.symbol,
        context: self.class.context
      )
        self.error_key = ErrorKey.new

        self.symbol = symbol
        self.message = message
        self.context = context
        self.category = category
        self.path = path
        self.runtime_path = runtime_path

        if !self.message.is_a?(String) || message.empty?
          # :nocov:
          raise "Bad error message, expected a string"
          # :nocov:
        end

        super(message)
      end

      def key
        error_key.to_s
      end

      def ==(other)
        equal?(other) || eql?(other)
      end

      def eql?(other)
        return false unless other.is_a?(Error)

        symbol == other.symbol
      end

      def to_h
        {
          key:,
          path:,
          runtime_path:,
          category:,
          symbol:,
          message:,
          context:
        }
      end
    end
  end
end
