Foobara.load_project(__dir__)

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
        create_can_methods
        create_register_callback_methods
      end
    end

    attr_accessor :current_state

    def initialize(*args, **options)
      super

      self.current_state = self.class.initial_state
    end

    def perform_transition!(transition, &block)
      from = current_state

      transition_map = self.class.transition_map

      if in_terminal_state?
        raise InvalidTransition,
              "#{current_state} is a terminal state so no transitions from here are allowed."
      end

      unless transition_map[current_state].key?(transition)
        raise InvalidTransition,
              "Cannot perform #{transition} from #{current_state}. Expected one of #{allowed_transitions}."
      end

      to = transition_map[current_state][transition]

      conditions = { from:, transition:, to: }

      callback_registry.runner(**conditions).callback_data(state_machine: self, **conditions).run do
        block.call if block_given?
        update_current_state(**conditions)
      end
    end

    def allowed_transitions
      if in_terminal_state?
        []
      else
        self.class.transition_map[current_state].keys
      end
    end

    def can?(transition)
      self.class.transition_map[current_state].key?(transition)
    end

    def update_current_state(**conditions)
      self.current_state = conditions[:to]
      log_transition(**conditions)
    end

    def in_terminal_state?
      self.class.terminal_states.include?(current_state)
    end
  end
end
