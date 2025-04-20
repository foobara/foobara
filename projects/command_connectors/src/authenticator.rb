module Foobara
  class CommandConnector
    class Authenticator
      attr_accessor :block, :explanation, :symbol

      def initialize(symbol: nil, explanation: nil, &block)
        symbol ||= Util.non_full_name_underscore(self.class).to_sym

        self.symbol = symbol
        self.block = block
        self.explanation = explanation || symbol
      end

      def to_proc
        block
      end
    end
  end
end
