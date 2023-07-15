module Foobara
  class StateMachine
    module Callbacks
      extend ActiveSupport::Concern

      ALLOWED_CALLBACK_TYPES = %i[before after around failure error].freeze

      # owner helps with determining the relevant object when running class-registered state transition callbacks
      attr_accessor :callback_registry, :owner

      def initialize(owner:)
        self.owner = owner
        self.callback_registry = CallbackRegistry.new
      end

      delegate :before_any_transition,
               :after_any_transition,
               :around_any_transition,
               :failure_any_transition,
               :error_any_transition,
               to: :callback_registry

      def register_transition_callback(*args, **options, &)
        type, from, transition, to = self.class.validate_and_normalize_register_callback_options(*args, **options)
        callback_registry.register_transition_callback(type, from:, to:, transition:, &)
      end

      private

      delegate :class_callback_registry, to: :class

      def callbacks_for(*args)
        callback_registry.callbacks_for(*args) + class_callback_registry.callbacks_for(*args)
      end

      def run_before_callbacks(from, transition, to)
        callbacks_for(:before, from, transition, to).each do |callback|
          callback.call(from:, transition:, to:, state_machine: self)
        end
      end

      def run_after_callbacks(from, transition, to)
        callbacks_for(:after, from, transition, to).each do |callback|
          callback.call(from:, transition:, to:, state_machine: self)
        end
      end

      def run_failure_callbacks(from, transition, to)
        callbacks_for(:failure, from, transition, to).each do |callback|
          callback.call(from:, transition:, to:, state_machine: self)
        end
      end

      def run_error_callbacks(error, from, transition, to)
        callbacks_for(:error, from, transition, to).each do |callback|
          callback.call(error:, from:, transition:, to:, state_machine: self)
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

      def has_before_callbacks?(from, transition, to)
        callback_registry.callbacks_for(:before, from, transition, to).present?
      end

      def has_after_callbacks?(from, transition, to)
        callback_registry.callbacks_for(:after, from, transition, to).present?
      end

      def has_around_callbacks?(from, transition, to)
        callback_registry.callbacks_for(:around, from, transition, to).present?
      end

      def has_error_callbacks?(from: nil, transition: nil, to: nil)
        callback_registry.callbacks_for(:error, from, transition, to).present?
      end

      def has_failure_callbacks?(from: nil, transition: nil, to: nil)
        callback_registry.callbacks_for(:failure, from, transition, to).present?
      end

      class_methods do
        def class_callback_registry
          @class_callback_registry ||= CallbackRegistry.new
        end

        def remove_all_callbacks
          @class_callback_registry = nil
        end

        def validate_and_normalize_register_callback_options(type, from: nil, to: nil, transition: nil)
          type = type.to_sym
          transition = transition&.to_sym
          from = from&.to_sym
          to = to&.to_sym

          unless ALLOWED_CALLBACK_TYPES.include?(type)
            raise "bad type #{type} expected one of #{ALLOWED_CALLBACK_TYPES}"
          end

          if transition && !transitions.include?(transition)
            raise "bad transition #{transition} expected one of #{transitions}"
          end

          if from && !states.include?(from)
            raise "bad from state #{from} expected one of #{states}"
          end

          if to && !states.include?(to)
            raise "bad to state #{to} expected one of #{states}"
          end

          [type, from, transition, to]
        end

        def register_transition_callback(*args, **options, &)
          type, from, transition, to = validate_and_normalize_register_callback_options(*args, **options)
          class_callback_registry.register_transition_callback(type, from:, to:, transition:, &)
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
      end
    end
  end
end