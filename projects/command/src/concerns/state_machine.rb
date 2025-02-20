module Foobara
  class Command < Service
    module Concerns
      module StateMachine
        def state_machine
          # It makes me nervous to pass self around. Seems like a design smell.
          @state_machine ||= Foobara::Command::StateMachine.new(owner: self)
        end
      end
    end
  end
end
