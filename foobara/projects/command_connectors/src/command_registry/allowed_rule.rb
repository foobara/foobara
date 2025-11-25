module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    class AllowedRule
      class << self
        def allowed_rule_attributes_type
          @allowed_rule_attributes_type ||= GlobalDomain.foobara_type_from_declaration(
            symbol: :symbol,
            # TODO: add a function type and a way to union two types so that we can string or function type checking
            explanation: :duck,
            logic: :duck
          )
        end
      end

      attr_accessor :block, :explanation, :symbol

      def initialize(symbol: nil, explanation: nil, &block)
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
