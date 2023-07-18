module Foobara
  class StateMachine
    module Callbacks
      extend ActiveSupport::Concern

      ALLOWED_CALLBACK_CONDITIONS = %i[from transition to].freeze

      # owner helps with determining the relevant object when running class-registered state transition callbacks
      attr_accessor :callback_registry, :owner

      def initialize(owner:)
        self.owner = owner
        self.callback_registry = Callback::ChainedRegistry.new(self.class.class_callback_registry)
      end

      delegate :callbacks_for,
               :before_any_transition,
               :after_any_transition,
               :around_any_transition,
               :failure_any_transition,
               :error_any_transition,
               :has_callbacks?,
               :has_before_callbacks?,
               :has_after_callbacks?,
               :has_around_callbacks?,
               :has_error_callbacks?,
               :has_failure_callbacks?,
               to: :callback_registry

      def register_transition_callback(type, **conditions, &)
        type, conditions = self.class.validate_and_normalize_register_callback_options(type, **conditions)
        callback_registry.register_callback(type, **conditions, &)
      end

      private

      def run_before_callbacks(**conditions)
        callbacks_for(:before, **conditions).each do |callback|
          callback.call(**conditions.merge(state_machine: self))
        end
      end

      def run_after_callbacks(**conditions)
        callbacks_for(:after, **conditions).each do |callback|
          callback.call(conditions.merge(state_machine: self))
        end
      end

      def run_failure_callbacks(**conditions)
        callbacks_for(:failure, **conditions).each do |callback|
          callback.call(conditions.merge(state_machine: self))
        end
      end

      def run_error_callbacks(error, **conditions)
        callbacks_for(:error, **conditions).each do |callback|
          callback.call(conditions.merge(error:, state_machine: self))
        end
      end

      def run_around_callbacks(**conditions, &block)
        around_callbacks = callbacks_for(:around, **conditions)

        if around_callbacks.blank?
          yield
        else
          # TODO: this never gets invoked?
          around_callbacks.reduce(block) do |nested_proc, callback|
            proc do
              callback.call(nested_proc, conditions.merge(state_machine: self))
            end
          end
        end
      end

      class_methods do
        def class_callback_registry
          @class_callback_registry ||= Callback::Registry.new(ALLOWED_CALLBACK_CONDITIONS)
        end

        def remove_all_callbacks
          @class_callback_registry = nil
        end

        def validate_and_normalize_register_callback_options(type, from: nil, to: nil, transition: nil)
          type = type.to_sym
          transition = transition&.to_sym
          from = from&.to_sym
          to = to&.to_sym

          if transition && !transitions.include?(transition)
            raise "bad transition #{transition} expected one of #{transitions}"
          end

          if from && !states.include?(from)
            raise "bad from state #{from} expected one of #{states}"
          end

          if to && !states.include?(to)
            raise "bad to state #{to} expected one of #{states}"
          end

          [type, { from:, transition:, to: }]
        end

        def register_transition_callback(type, **conditions, &)
          type, conditions = validate_and_normalize_register_callback_options(type, **conditions)
          class_callback_registry.register_callback(type, **conditions, &)
        end

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

          Foobara::Callback::Registry::ALLOWED_CALLBACK_TYPES.each do |type|
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
      end
    end
  end
end
