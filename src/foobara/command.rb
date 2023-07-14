module Foobara
  class Command
    include Schemas
    include Runtime

    def state_machine
      @state_machine ||= StateMachine.new
    end
  end
end
