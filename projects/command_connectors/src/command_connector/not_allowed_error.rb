module Foobara
  class CommandConnector
    class NotAllowedError < CommandConnectorError
      class << self
        def for(rule_symbol: nil, explanation: nil)
          rule_symbol ||= :no_symbol_declared
          message = "Not allowed"
          if explanation
            message += ": #{explanation}"
          end
          explanation ||= "No explanation"
          context = { rule_symbol:, explanation: }

          new(message:, context:)
        end
      end

      context do
        rule_symbol :symbol, :required
        explanation :string, :required
      end
    end
  end
end
