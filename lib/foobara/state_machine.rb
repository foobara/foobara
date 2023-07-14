module Foobara
  class StateMachine
    include Sugar
    include Callbacks
    include Validations
    include TransitionLog

    class InvalidTransition < StandardError; end

    class << self
      attr_accessor :transitions, :initial_state, :states, :non_terminal_states, :terminal_states, :transition_map,
                    :raw_transition_map, :state, :transition

      def set_transition_map(transition_map, initial_state: nil, states: nil, terminal_states: nil, transitions: nil)
        self.raw_transition_map = transition_map

        self.initial_state = initial_state
        self.states = states
        self.terminal_states = terminal_states
        self.transitions = transitions

        desugarize_transition_map
        determine_states_and_transitions

        create_enums
        create_state_predicate_methods
        create_transition_methods
        create_register_callback_methods
      end
    end

    attr_accessor :current_state

    def initialize
      super

      self.current_state = self.class.initial_state
    end

    def perform_transition!(transition, successful_if: nil, allowed_error_classes: [])
      from = current_state

      transition_map = self.class.transition_map

      unless transition_map[current_state].key?(transition)
        raise InvalidTransition,
              "Cannot perform #{transition} from #{current_state}. Expected one of #{allowed_transitions}."
      end

      to = transition_map[current_state][transition]

      if block_given?
        run_before_callbacks(from, transition, to)
        run_around_callbacks(from, transition, to) do
          begin
            yield
          rescue => e
            if allowed_error_classes.none? { |klass| klass === e }
              run_error_callbacks(e, from, transition, to)
            else
              update_current_state(from, transition, to)
            end

            raise
          end

          if successful_if.nil? || successful_if.call
            update_current_state(from, transition, to)
          else
            run_failure_callbacks(from, transition, to)
          end
        end
      else
        # TODO: raise better errors
        raise if successful_if
        raise if allowed_error_classes.present?
        raise if has_before_callbacks?(from, transition, to)
        raise if has_around_callbacks?(from, transition, to)

        update_current_state(from, transition, to)
      end
    end

    def allowed_transitions
      transition_map[current_state].keys
    end

    def can?(transition)
      transition_map[current_state].key?(transition)
    end

    def update_current_state(from, transition, to)
      self.current_state = to
      log_transition(from, transition, to)
      run_after_callbacks(from, transition, to)
    end
  end
end
