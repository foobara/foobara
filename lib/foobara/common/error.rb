module Foobara
  class Error < StandardError
    attr_accessor :symbol, :message, :context

    class << self
      def symbol
        name.demodulize.underscore.gsub(/_error$/, "").to_sym
      end
    end

    def initialize(message:, symbol: self.class.symbol, context: {})
      super(message)

      self.symbol =  symbol
      self.message = message
      self.context = context
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
        symbol:,
        message:,
        context:
      }
    end
  end
end
