module Foobara
  class StateMachine
    module Sugar
      class TransitionAlreadyDefinedError < StandardError; end
      class BadInitialState < StandardError; end

      extend ActiveSupport::Concern

      class_methods do
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

        def create_enums
          self.state = Enumerated::Values.new(states)
          self.transition = Enumerated::Values.new(transitions)
        end

        def create_state_predicate_methods
          states.each do |state|
            define_method "currently_#{state}?" do
              current_state == state
            end

            define_method "ever_#{state}?" do
              current_state == state || log.any? { |log_entry| log_entry.from_state == state }
            end
          end
        end

        def create_transition_methods
          transitions.each do |transition|
            define_method "#{transition}!" do
              perform_transition!(transition)
            end
          end
        end
      end
    end
  end
end
