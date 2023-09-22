module Foobara
  class StateMachine
    module Callbacks
      include Concern

      # owner helps with determining the relevant object when running class-registered state transition callbacks
      attr_accessor :callback_registry, :owner

      def initialize(owner: nil)
        self.owner = owner
        self.callback_registry = Callback::Registry::ChainedConditioned.new(self.class.class_callback_registry)
      end

      delegate :callbacks_for,
               :has_callbacks?,
               :has_before_callbacks?,
               :has_after_callbacks?,
               :has_around_callbacks?,
               :has_error_callbacks?,
               :has_failure_callbacks?,
               to: :callback_registry

      def register_transition_callback(type, **, &)
        callback_registry.register_callback(type, **, &)
      end

      module ClassMethods
        def class_callback_registry
          @class_callback_registry ||= Callback::Registry::Conditioned.new(
            from: states,
            transition: transitions,
            to: states
          )
        end

        def remove_all_callbacks
          @class_callback_registry = nil
        end

        def register_transition_callback(type, **, &)
          class_callback_registry.register_callback(type, **, &)
        end

        attr_reader :register_callback_methods

        # 0 before_any_transition
        # 1 before_transition_to_<state>
        # 2 before_transition_from_<state>
        # 3 before_transition_from_<state>_to_<state>
        # 4 before_<transition>_transition
        # 5 before_<transition>_transition_to_<state>
        # 6 before_<transition>_transition_from_<state>
        def create_register_callback_methods
          if register_callback_methods
            # :nocov:
            raise "Do not create register callback methods twice"
            # :nocov:
          end

          callback_methods = @register_callback_methods = []

          tos = Set.new
          transitions = Set.new
          froms = Set.new

          froms_to_tos = Set.new
          transitions_to_tos = Set.new
          froms_to_transitions = Set.new
          froms_transitions_tos = Set.new

          transition_map.each_pair do |from, to_map|
            froms << from
            to_map.each_pair do |transition, to|
              transitions << transition
              tos << to
              froms_to_tos << [from, to]
              transitions_to_tos << [transition, to]
              froms_to_transitions << [from, transition]
              froms_transitions_tos << [from, transition, to]
            end
          end

          Foobara::Callback::Block.types.each do |type|
            method_name = "#{type}_any_transition"
            callback_methods << method_name

            define_method method_name do |&block|
              register_transition_callback(type, &block)
            end

            froms.each do |from|
              method_name = "#{type}_transition_from_#{from}"
              callback_methods << method_name

              define_method method_name do |&block|
                register_transition_callback(type, from:, &block)
              end
            end

            transitions.each do |transition|
              method_name = "#{type}_#{transition}"
              callback_methods << method_name

              define_method method_name do |&block|
                register_transition_callback(type, transition:, &block)
              end
            end

            tos.each do |to|
              method_name = "#{type}_transition_to_#{to}"
              callback_methods << method_name

              define_method method_name do |&block|
                register_transition_callback(type, to:, &block)
              end
            end

            froms_to_tos.each do |(from, to)|
              method_name = "#{type}_transition_from_#{from}_to_#{to}"
              callback_methods << method_name

              define_method method_name do |&block|
                register_transition_callback(type, to:, from:, &block)
              end
            end

            transitions_to_tos.each do |(transition, to)|
              method_name = "#{type}_#{transition}_to_#{to}"
              callback_methods << method_name

              define_method method_name do |&block|
                register_transition_callback(type, transition:, to:, &block)
              end
            end

            froms_to_transitions.each do |(from, transition)|
              method_name = "#{type}_#{transition}_from_#{from}"
              callback_methods << method_name

              define_method method_name do |&block|
                register_transition_callback(type, transition:, from:, &block)
              end
            end

            froms_transitions_tos.each do |(from, transition, to)|
              method_name = "#{type}_#{transition}_from_#{from}_to_#{to}"
              callback_methods << method_name

              define_method method_name do |&block|
                register_transition_callback(type, transition:, from:, to:, &block)
              end
            end
          end
        end
      end
    end
  end
end
