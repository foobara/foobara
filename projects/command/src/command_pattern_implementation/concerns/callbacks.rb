require_relative "../../state_machine"

module Foobara
  module CommandPatternImplementation
    module Concerns
      module Callbacks
        include Concern

        module ClassMethods
          def state_machine_callback_registry
            return @state_machine_callback_registry if defined?(@state_machine_callback_registry)

            @state_machine_callback_registry = if superclass.respond_to?(:state_machine_callback_registry)
                                                 Callback::Registry::ChainedConditioned.new(
                                                   superclass.state_machine_callback_registry
                                                 )
                                               else
                                                 Callback::Registry::Conditioned.new(
                                                   from: Foobara::Command::StateMachine.states,
                                                   transition: Foobara::Command::StateMachine.transitions,
                                                   to: Foobara::Command::StateMachine.states
                                                 )
                                               end
          end

          def remove_all_callbacks
            Foobara::Command::StateMachine.remove_all_callbacks
            if defined?(@state_machine_callback_registry)
              remove_instance_variable(:@state_machine_callback_registry)
            end
          end
        end

        [self, ClassMethods].each do |target|
          [:before, :after].each do |type|
            target.define_method "#{type}_any_transition" do |&block|
              state_machine_callback_registry.register_callback(type) do |state_machine:, **args|
                block.call(command: state_machine.owner, **args)
              end
            end
          end

          target.define_method "around_any_transition" do |&block|
            state_machine_callback_registry.register_callback(
              :around
            ) do |state_machine:, **args, &do_transition_block|
              block.call(command: state_machine.owner, **args, &do_transition_block)
            end
          end

          target.define_method :error_any_transition do |&block|
            state_machine_callback_registry.register_callback(:error) do |error|
              callback_data = error.callback_data

              state_machine = callback_data[:state_machine]
              command = state_machine.owner
              from = callback_data[:from]
              transition = callback_data[:transition]
              to = callback_data[:to]

              block.call(error:, command:, state_machine:, from:, to:, transition:)
            end
          end
        end

        Foobara::Command::StateMachine.transitions.each do |transition|
          [self, ClassMethods].each do |target|
            [:before, :after].each do |type|
              target.define_method "#{type}_#{transition}" do |&block|
                state_machine_callback_registry.register_callback(
                  type, transition:
                ) do |state_machine:, **args|
                  block.call(command: state_machine.owner, **args)
                end
              end
            end

            target.define_method "around_#{transition}" do |&block|
              state_machine_callback_registry.register_callback(
                :around, transition:
              ) do |state_machine:, **args, &do_transition_block|
                block.call(command: state_machine.owner, **args, &do_transition_block)
              end
            end
          end
        end

        def state_machine_callback_registry
          state_machine.callback_registry
        end
      end
    end
  end
end
