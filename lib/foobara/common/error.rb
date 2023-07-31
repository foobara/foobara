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

    def initialize(message:, symbol: nil, context: {})
      super(message)

      self.symbol = if symbol
                      symbol
                    elsif self.class.respond_to?(:symbol)
                      self.class.symbol
                    else
                      raise NoErrorSymbolGiven, "No error symbol given"
                    end

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
