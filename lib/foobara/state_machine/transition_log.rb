module Foobara
  class StateMachine
    module TransitionLog
      extend ActiveSupport::Concern

      attr_accessor :log

      def initialize(*args, **options)
        super

        self.log = []
      end

      def log_transition(**conditions)
        log << LogEntry.new(**conditions)
      end
    end
  end
end
