module Foobara
  class Type
    class ValueProcessor
      attr_accessor :outcome

      def initialize(outcome)
        self.outcome = outcome
      end

      def process
        raise "subclass responsibility"
      end
    end
  end
end
