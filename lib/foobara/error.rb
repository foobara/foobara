module Foobara
  class Error < StandardError
    attr_accessor :symbol, :message, :context

    def initialize(symbol, message, context = {})
      super(message)

      self.symbol = symbol
      self.message = message
      self.context = context || {}.with_indifferent_access
    end
  end
end
