module Foobara
  module CommandPatternImplementation
    module Concerns
      module StateMachine
        def state_machine
          return @state_machine if defined?(@state_machine)

          # It makes me nervous to pass self around. Seems like a design smell.
          @state_machine = Foobara::Command::StateMachine.new(owner: self)

          @state_machine.callback_registry = Callback::Registry::JoinedConditioned.new(
            @state_machine.callback_registry,
            self.class.state_machine_callback_registry
          )

          @state_machine
        end
      end
    end
  end
end
