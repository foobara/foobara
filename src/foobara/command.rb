module Foobara
  class Command
    include InputSchema
    include ResultSchema
    include Runtime
    include Callbacks

    def state_machine
      # It makes me nervous to pass self around. Seems like a design smell.
      @state_machine ||= StateMachine.new(owner: self)
    end
  end
end
