module Foobara
  class StateMachine
    class CallbackRegistry
      attr_accessor :callbacks

      def initialize
        self.callbacks = {}
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
        if type == :around
          if block.arity != 1
            raise "around callbacks must take exactly one argument which will be the perform_transition proc"
          end
        elsif block.arity != 0
          raise "#{type} callback should take exactly 0 arguments"
        end

        callbacks_for_triple = callbacks[type] ||= {}
        blocks = callbacks_for_triple[[from, transition, to]] ||= []

        blocks << block
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
    end
  end
end
