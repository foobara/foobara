module Foobara
  class CommandConnector
    class NotAllowedError < CommandConnectorError
      class << self
        def context_type_declaration
          {
            rule_symbol: :symbol,
            explanation: :string
          }
        end
      end

      attr_accessor :rule_symbol, :explanation

      def initialize(rule_symbol:, explanation:)
        self.rule_symbol = rule_symbol || :no_symbol_declared
        self.explanation = explanation || "No explanation"

        super("Not allowed: #{explanation}", context:)
      end

      def context
        { rule_symbol:, explanation: }
      end
    end
  end
end
