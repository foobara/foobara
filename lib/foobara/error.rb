module Foobara
  class Error < StandardError
    attr_accessor :symbol, :message, :context

    def initialize(symbol:, message:, context: nil)
      super(message)

      self.symbol = symbol
      self.message = message
      self.context = context
    end
  end
end
