module Foobara
  class StateMachine
    module Callbacks
      extend ActiveSupport::Concern

      ALLOWED_CALLBACK_TYPES = %i[before after around failure error].freeze

      attr_accessor :callbacks

      def initialize
        super
        self.callbacks = {}
      end

      delegate :has_before_callbacks?,
               :has_after_callbacks?,
               :has_around_callbacks?,
               :has_error_callbacks?,
               :has_failure_callbacks?,
               :callbacks_for,
               to: :class

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
        transition = transition&.to_sym
        from = from&.to_sym
        to = to&.to_sym

        raise "bad type #{type} expected one of #{ALLOWED_CALLBACK_TYPES}" unless ALLOWED_CALLBACK_TYPES.include?(type)

        transitions = self.class.transitions

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

        callbacks_for_triple = callbacks[type] ||= {}
        blocks = callbacks_for_triple[[from, transition, to]] ||= []

        blocks << block
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

      # these two seem to have awkward names
      def failure_any_transition(&)
        register_transition_callback(:failure, &)
      end

      def error_any_transition(&)
        register_transition_callback(:error, &)
      end

      private

      def run_before_callbacks(from, transition, to)
        callbacks_for(:before, from, transition, to).each do |callback|
          callback.call(from:, transition:, to:)
        end
      end

      def run_after_callbacks(from, transition, to)
        callbacks_for(:after, from, transition, to).each do |callback|
          callback.call(from:, transition:, to:)
        end
      end

      def run_failure_callbacks(from, transition, to)
        callbacks_for(:failure, from, transition, to).each do |callback|
          callback.call(from:, transition:, to:)
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
              callback.call(nested_proc, transition:, to:)
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

      class_methods do
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
              define_method "#{type}_transition_from_#{from}" do |&block|
                register_transition_callback(type, from:, &block)
              end
            end

            tos.each do |to|
              define_method "#{type}_transition_to_#{to}" do |&block|
                register_transition_callback(type, to:, &block)
              end
            end

            froms_to_tos.each do |(from, to)|
              define_method "#{type}_transition_from_#{from}_to_#{to}" do |&block|
                register_transition_callback(type, to:, from:, &block)
              end
            end

            transitions_to_tos.each do |(transition, to)|
              define_method "#{type}_#{transition}_to_#{to}" do |&block|
                register_transition_callback(type, transition:, to:, &block)
              end
            end

            froms_to_transitions.each do |(from, transition)|
              define_method "#{type}_#{transition}_from_#{from}" do |&block|
                register_transition_callback(type, transition:, from:, &block)
              end
            end
          end
        end

        def callback_lookup(type, triple)
          callbacks[type]&.[](triple)
        end
      end
    end
  end
end
