module Foobara
  class StateMachine
    LogEntry = Struct.new(:from_state, :transition, :to_state)

    ALLOWED_CALLBACK_TYPES = %i[before after around failure error]

    class TransitionAlreadyDefinedError < StandardError; end
    class UnexpectedTerminalStates < StandardError; end
    class MissingStates < StandardError; end
    class ExtraStates < StandardError; end
    class MissingTransitions < StandardError; end
    class ExtraTransitions < StandardError; end
    class BadInitialState < StandardError; end
    class MissingTerminalStates < StandardError; end
    class InvalidTransition < StandardError; end

    attr_accessor :transitions, :initial_state, :states, :non_terminal_states, :terminal_states, :transition_map,
                  :raw_transition_map, :state, :transition, :current_state, :log, :callbacks

    def initialize(transition_map, initial_state: nil, states: nil, terminal_states: nil, transitions: nil)
      self.log = []
      self.callbacks = {}

      self.raw_transition_map = transition_map

      self.initial_state = initial_state
      self.states = states
      self.terminal_states = terminal_states
      self.transitions = transitions

      desugarize_transition_map
      determine_states_and_transitions

      self.current_state = self.initial_state

      create_enums
      create_state_predicate_methods
      create_transition_methods
      create_register_callback_methods
    end

    def perform_transition!(transition, successful_if: nil, allowed_error_classes: [])
      from = current_state

      unless  transition_map[current_state].key?(transition)
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

    # nil versus not-nil for the various callback-scope options
    #
    #      type     from transition   to notes
    #      ----     ---- ----------   -- -----
    # *     nil      nil        nil  nil # illegal! must have at least type
    # 0 :before      nil        nil  nil # before any transition
    # 1 :before      nil        nil :ran # before any transition to :ran
    # 2 :before      nil       :run  nil # before :run transition from any state to any state
    # 3 :before      nil       :run :ran # before any transition from any state to :ran
    # 4 :before :pending        nil  nil # before any transition from the :pending state
    # 5 :before :pending        nil :ran # before any transition from :pending and to :ran
    # 6 :before :pending       :run  nil # before :run transition from :pending and to any state
    # 7 :before :pending       :run :ran # illegal! dont use all three!
    #
    # So there are 7 legal transition callback scopes corresponding to the above
    # 0 before_any_transition
    # 1 before_transition_to_<state>
    # 2 before_transition_from_<state>
    # 3 before_transition_from_<state>_to_<state>
    # 4 before_<transition>_transition
    # 5 before_<transition>_transition_to_<state>
    # 6 before_<transition>_transition_from_<state>
    def register_transition_callback(type, from: nil, to: nil, transition: nil, &block)
      type = type.to_sym
      transition = transition.to_sym
      from = from.to_sym
      to = to.to_sym

      raise "bad type #{type} expected one of #{ALLOWED_CALLBACK_TYPES}" unless types.include?

      if transition && !transitions.include?(transition)
        raise "bad transition #{transition} expected one of #{transitions}"
      end

      if from && !states.include?(from)
        raise "bad from state #{from} expected one of #{states}"
      end

      if to && !states.include?(to)
        raise "bad to state #{to} expected one of #{states}"
      end

      if type == :around
        if block.arity != 1
          raise "around callbacks must take exactly one argument which will be the perform_transition proc"
        end
      elsif block.arity != 0
        raise "#{type} callback should take exactly 0 arguments"
      end
      type_callbacks = callbacks[type] ||= {}
      triple_callbacks = type_callbacks[triple] ||= []

      triple_callbacks << block
    end

    def before_any_transition(&)
      register_transition_callback(:before, &)
    end

    def after_any_transition(&)
      register_transition_callback(:after, &)
    end

    def around_any_transition(&)
      register_transition_callback(:around, &)
    end

    def failure_any_transition(&)
      register_transition_callback(:failure, &)
    end

    def error_any_transition(&)
      register_transition_callback(:error, &)
    end

    private

    def has_before_callbacks?(from, transition, to)
      callbacks_for(:before, from, transition, to).present?
    end

    def has_after_callbacks?(from, transition, to)
      callbacks_for(:after, from, transition, to).present?
    end

    def has_around_callbacks?(from, transition, to)
      callbacks_for(:around, from, transition, to).present?
    end

    def has_error_callbacks?(from: nil, transition: nil, to: nil)
      callbacks_for(:error, from, transition, to).present?
    end

    def has_failure_callbacks?(from: nil, transition: nil, to: nil)
      callbacks_for(:failure, from, transition, to).present?
    end

    def run_before_callbacks(from, transition, to)
      callbacks_for(:before, from, transition, to) do |callback|
        callback.call(from:, transition:, to:, state_machine: self)
      end
    end

    def run_after_callbacks(from, transition, to)
      callbacks_for(:after, from, transition, to) do |callback|
        callback.call(from:, transition:, to:, state_machine: self)
      end
    end

    def run_failure_callbacks(from, transition, to)
      callbacks_for(:failure, from, transition, to) do |callback|
        callback.call(from:, transition:, to:, state_machine: self)
      end
    end

    def run_error_callbacks(error, from, transition, to)
      callbacks_for(:error, from, transition, to).each do |callback|
        callback.call(error:, from:, transition:, to:)
      end
    end

    def run_around_callbacks(from, transition, to, &block)
      around_callbacks = callbacks_for(:around, from, transition, to)

      if around_callbacks.blank?
        yield
      else
        around_callbacks.reduce(block) do |nested_proc, callback|
          proc do
            callback.call(nested_proc, transition:, to:, state_machine: self)
          end
        end
      end
    end

    def callbacks_for(type, from, transition, to)
      raise unless type.present?
      raise unless from.present?
      raise unless transition.present?
      raise unless to.present?

      callbacks_for_type = callbacks[type]

      return [] if callbacks_for_type.blank?

      all_callbacks = []

      # 0
      triple = [nil, nil, nil]
      scoped_callbacks = callbacks_for_type[triple]
      all_callbacks += scoped_callbacks if scoped_callbacks.present?

      # 1
      triple[2] = to
      scoped_callbacks = callbacks_for_type[triple]
      all_callbacks += scoped_callbacks if scoped_callbacks.present?

      # 2
      triple[1] = transition
      triple[2] = nil
      scoped_callbacks = callbacks_for_type[triple]
      all_callbacks += scoped_callbacks if scoped_callbacks.present?

      # 4
      triple[0] = from
      triple[1] = nil
      scoped_callbacks = callbacks_for_type[triple]
      all_callbacks += scoped_callbacks if scoped_callbacks.present?

      # 3
      triple[0] = nil
      triple[1] = transition
      triple[2] = to
      scoped_callbacks = callbacks_for_type[triple]
      all_callbacks += scoped_callbacks if scoped_callbacks.present?

      # 5
      triple[0] = from
      triple[1] = nil
      scoped_callbacks = callbacks_for_type[triple]
      all_callbacks += scoped_callbacks if scoped_callbacks.present?

      # 6
      triple[1] = transition
      triple[2] = nil
      scoped_callbacks = callbacks_for_type[triple]
      all_callbacks += scoped_callbacks if scoped_callbacks.present?

      all_callbacks # should we reverse these?
    end

    def update_current_state(from, transition, to)
      self.current_state = to
      log << LogEntry.new(from, transition, to)
      run_after_callbacks(from, transition, to)
    end

    def callback_lookup(type, triple)
      callbacks[type]&.[](triple)
    end

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

    def create_state_predicate_methods
      states.each do |state|
        singleton_class.define_method "currently_#{state}?" do
          current_state == state
        end

        singleton_class.define_method "ever_#{state}?" do
          current_state == state || log.any? { |log_entry| log_entry.from_state == state }
        end
      end
    end

    def create_transition_methods
      transitions.each do |transition|
        singleton_class.define_method "#{transition}!" do
          perform_transition!(transition)
        end
      end
    end

    # TODO: figure out a way to not have to declare these for every instance of the state machine, wtf
    def create_register_callback_methods
      # 0 before_any_transition
      # 1 before_transition_to_<state>
      # 2 before_transition_from_<state>
      # 3 before_transition_from_<state>_to_<state>
      # 4 before_<transition>_transition
      # 5 before_<transition>_transition_to_<state>
      # 6 before_<transition>_transition_from_<state>

      tos = Set.new
      froms = Set.new

      froms_to_tos = Set.new
      transitions_to_tos = Set.new
      froms_to_transitions = Set.new

      # ALLOWED_CALLBACK_TYPES = %i[before after around failure error]
      transition_map.each_pair do |from, to_map|
        froms << from
        to_map.each_pair do |transition, to|
          tos << to
          froms_to_tos << [from, to]
          transitions_to_tos << [transition, to]
          froms_to_transitions << [from, transition]
        end
      end

      ALLOWED_CALLBACK_TYPES.each do |type|
        froms.each do |from|
          singleton_class.define_method "#{type}_transition_from_#{from}" do |&block|
            register_transition_callback(type, from:, &block)
          end
        end

        tos.each do |to|
          singleton_class.define_method "#{type}_transition_to_#{to}" do |&block|
            register_transition_callback(type, to:, &block)
          end
        end

        froms_to_tos.each do |(from, to)|
          singleton_class.define_method "#{type}_transition_from_#{from}_to_#{to}" do |&block|
            register_transition_callback(type, to:, from:, &block)
          end
        end

        transitions_to_tos.each do |(transition, to)|
          singleton_class.define_method "#{type}_#{transition}_to_#{to}" do |&block|
            register_transition_callback(type, transition:, to:, &block)
          end
        end

        froms_to_transitions.each do |(from, transition)|
          singleton_class.define_method "#{type}_#{transition}_from_#{from}" do |&block|
            register_transition_callback(type, transition:, from:, &block)
          end
        end
      end

      def before_any_transition(&)
        register_transition_callback(:before, &)
      end
    end
  end
end
