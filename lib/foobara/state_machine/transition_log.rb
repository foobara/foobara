module Foobara
  class StateMachine
    module TransitionLog
      extend ActiveSupport::Concern

      attr_accessor :log

      def initialize
        super

        self.log = []
      end

      def log_transition(from, transition, to)
        log << LogEntry.new(from, transition, to)
      end
    end
  end
end
