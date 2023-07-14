module Foobara
  class StateMachine
    LogEntry = Struct.new(:from_state, :transition, :to_state)
  end
end
