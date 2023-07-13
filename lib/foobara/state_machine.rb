module Foobara
  class StateMachine
    class TransitionAlreadyDefinedError < StandardError; end
    class UnexpectedTerminalStates < StandardError; end
    class MissingStates < StandardError; end
    class ExtraStates < StandardError; end
    class MissingTransitions < StandardError; end
    class ExtraTransitions < StandardError; end
    class BadInitialState < StandardError; end
    class MissingTerminalStates < StandardError; end

    attr_accessor :transitions, :initial_state, :states, :non_terminal_states, :terminal_states, :transition_map,
                  :raw_transition_map, :state, :transition

    def initialize(transition_map, initial_state: nil, states: nil, terminal_states: nil, transitions: nil)
      self.raw_transition_map = transition_map

      self.initial_state = initial_state
      self.states = states
      self.terminal_states = terminal_states
      self.transitions = transitions

      desugarize_transition_map
      determine_states_and_transitions
      create_enums
    end

    private

    def desugarize_transition_map
      self.transition_map = {}

      raw_transition_map.each_pair do |from_state, transitions|
        Array.wrap(from_state).each do |state|
          state = state.to_sym

          transitions.each_pair do |transition, next_state|
            transition = transition.to_sym
            next_state = next_state.to_sym

            transitions_for_state = transition_map[state] ||= {}

            if transitions_for_state.key?(transition)
              raise TransitionAlreadyDefinedError, "There's already a #{transition} for #{state}"
            end

            transitions_for_state[transition] = next_state
          end
        end
      end

      transition_map.freeze
    end

    def determine_states_and_transitions
      computed_non_terminal_states = transition_map.keys.uniq
      computed_terminal_states = []
      computed_transitions = []

      transition_map.each_value do |transitions|
        transitions.each_pair do |transition, to_state|
          computed_transitions << transition unless computed_transitions.include?(transition)

          if !computed_non_terminal_states.include?(to_state) && !computed_terminal_states.include?(to_state)
            computed_terminal_states << to_state
          end
        end
      end

      if terminal_states
        all_states = computed_non_terminal_states + computed_terminal_states
        validate_terminal_states(computed_terminal_states, all_states)
        # User has marked states as explicitly terminal even though they might have transitions
        # This is allowed. So fix any such computations.
        computed_non_terminal_states -= terminal_states
        computed_terminal_states |= terminal_states
      else
        self.terminal_states = computed_terminal_states.freeze
      end

      self.non_terminal_states = computed_non_terminal_states.freeze

      computed_states = computed_non_terminal_states + computed_terminal_states

      if states
        validate_states(computed_states)
      else
        self.states = computed_states.freeze
      end

      if transitions
        validate_transitions(computed_transitions)
      else
        self.transitions = computed_transitions.freeze
      end

      if initial_state
        unless states.include?(initial_state)
          raise BadInitialState, "Initial state explicitly set to #{
            initial_state
          } but should have been one of #{states}"
        end
      else
        self.initial_state = states.first
      end
    end

    def validate_terminal_states(computed_terminal_states, all_states)
      unexpected_terminal_states = computed_terminal_states - terminal_states

      if unexpected_terminal_states.present?
        raise UnexpectedTerminalStates, "#{
          unexpected_terminal_states
        } do(es) not have transitions even though they are not in the explicit list of terminal states #{
          terminal_states
        }"
      end

      missing_terminal_states = terminal_states - all_states

      if missing_terminal_states.present?
        raise MissingTerminalStates, "#{
          missing_terminal_states
        } was/were included explicitly in terminal_states but didn't appear in the transition map"
      end
    end

    def validate_states(computed_states)
      missing_states = states - computed_states

      if missing_states.present?
        binding.pry
        raise MissingStates,
              "#{missing_states} is/are explicitly declared as states but do(es)n't appear in the transition map"
      end

      extra_states = computed_states - states

      if extra_states.present?
        raise ExtraStates, "#{extra_states} appeared in the transition map but were not explicitly declared as states"
      end
    end

    def validate_transitions(computed_transitions)
      missing_transitions = transitions - computed_transitions

      if missing_transitions.present?
        raise MissingTransitions, "#{
        missing_transitions
      } is/are explicitly declared as transitions but do(es)n't appear in the transition map"
      end

      extra_transitions = computed_transitions - transitions

      if extra_transitions.present?
        raise ExtraTransitions,
              "#{extra_transitions} appeared in the transition map but were not explicitly declared as transitions"
      end
    end

    def create_enums
      self.state = Enumerated::Values.new(states)
      self.transition = Enumerated::Values.new(transitions)
    end
  end
end
