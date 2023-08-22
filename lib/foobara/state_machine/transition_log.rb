module Foobara
  class StateMachine
    module TransitionLog
      extend ActiveSupport::Concern

      attr_accessor :log

      def initialize(*args, **options)
        super

        self.log = []
      end

      def log_transition(**)
        log << LogEntry.new(**)
      end
    end
  end
end
