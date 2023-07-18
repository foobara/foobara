module Foobara
  class StateMachine
    class LogEntry
      attr_accessor :from, :transition, :to

      def initialize(from:, transition:, to:)
        self.from = from
        self.transition = transition
        self.to = to
      end
    end
  end
end
