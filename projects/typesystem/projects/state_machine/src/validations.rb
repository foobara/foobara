module Foobara
  class StateMachine
    module Validations
      include Concern

      class UnexpectedTerminalStates < StandardError; end
      class MissingStates < StandardError; end
      class ExtraStates < StandardError; end
      class MissingTransitions < StandardError; end
      class ExtraTransitions < StandardError; end
      class MissingTerminalStates < StandardError; end

      module ClassMethods
        def validate_terminal_states(computed_terminal_states, all_states)
          unexpected_terminal_states = computed_terminal_states - terminal_states

          unless unexpected_terminal_states.empty?
            raise UnexpectedTerminalStates, "#{
            unexpected_terminal_states
          } do(es) not have transitions even though they are not in the explicit list of terminal states #{
            terminal_states
          }"
          end

          missing_terminal_states = terminal_states - all_states

          unless missing_terminal_states.empty?
            raise MissingTerminalStates, "#{
            missing_terminal_states
          } was/were included explicitly in terminal_states but didn't appear in the transition map"
          end
        end

        def validate_states(computed_states)
          missing_states = states - computed_states

          unless missing_states.empty?
            raise MissingStates,
                  "#{missing_states} is/are explicitly declared as states but do(es)n't appear in the transition map"
          end

          extra_states = computed_states - states

          unless extra_states.empty?
            raise ExtraStates,
                  "#{extra_states} appeared in the transition map but were not explicitly declared as states"
          end
        end

        def validate_transitions(computed_transitions)
          missing_transitions = transitions - computed_transitions

          unless missing_transitions.empty?
            raise MissingTransitions, "#{
            missing_transitions
          } is/are explicitly declared as transitions but do(es)n't appear in the transition map"
          end

          extra_transitions = computed_transitions - transitions

          unless extra_transitions.empty?
            raise ExtraTransitions,
                  "#{extra_transitions} appeared in the transition map but were not explicitly declared as transitions"
          end
        end
      end
    end
  end
end
