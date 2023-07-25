module Foobara
  class Error < StandardError
    attr_accessor :symbol, :message, :context

    class << self
      def type
        name.demodulize.underscore.gsub(/_error$/, "").to_sym
      end

      def merge(errors)
        MultipleError.new(errors)
      end
    end

    def initialize(symbol:, message:, context: nil)
      super(message)

      self.symbol = symbol
      self.message = message
      self.context = context
    end

    delegate :type, to: :class

    def ==(other)
      equal?(other) || eql?(other)
    end

    def eql?(other)
      return false unless other.is_a?(Error)

      symbol == other.symbol
    end

    def to_h
      {
        type:,
        symbol:,
        message:,
        context:
      }
    end
  end
end
