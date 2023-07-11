module Foobara
  class Error
    attr_accessor :symbol, :message, :context

    def initialize(symbol, message, context = {})
      self.symbol = symbol
      self.message = message
      self.context = context || {}.with_indifferent_access
    end
  end
end
