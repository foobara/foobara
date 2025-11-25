module Foobara
  class StateMachine
    module Transitions
      include Concern

      module ClassMethods
        def states_that_can_perform(transition)
          states = []
          transition = transition.to_sym

          transition_map.each_pair do |from, transitions|
            if transitions.key?(transition)
              states << from
            end
          end

          states
        end
      end
    end
  end
end
