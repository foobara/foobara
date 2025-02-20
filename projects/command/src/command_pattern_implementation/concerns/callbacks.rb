module Foobara
  class Command
    module Concerns
      module Callbacks
        include Concern

        inherited_overridable_class_attr_accessor :subclass_defined_callbacks

        module ClassMethods
          def inherited(subclass)
            super

            subclass_defined_callbacks.runner.callback_data(subclass).run
          end

          def after_subclass_defined(&)
            subclass_defined_callbacks.register_callback(:after, &)
          end

          def callback_state_machine_target
            Foobara::Command::StateMachine
          end

          foobara_delegate :remove_all_callbacks, to: :callback_state_machine_target
        end

        on_include do
          self.subclass_defined_callbacks ||= Foobara::Callback::Registry::SingleAction.new

          [self, singleton_class].each do |target|
            %i[before after].each do |type|
              target.define_method "#{type}_any_transition" do |&block|
                callback_state_machine_target.register_transition_callback(type) do |state_machine:, **args|
                  block.call(command: state_machine.owner, **args)
                end
              end
            end

            target.define_method "around_any_transition" do |&block|
              callback_state_machine_target.register_transition_callback(
                :around
              ) do |state_machine:, **args, &do_transition_block|
                block.call(command: state_machine.owner, **args, &do_transition_block)
              end
            end

            target.define_method :error_any_transition do |&block|
              callback_state_machine_target.register_transition_callback(:error) do |error|
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
            [self, singleton_class].each do |target|
              %i[before after].each do |type|
                target.define_method "#{type}_#{transition}" do |&block|
                  callback_state_machine_target.register_transition_callback(
                    type, transition:
                  ) do |state_machine:, **args|
                    block.call(command: state_machine.owner, **args)
                  end
                end
              end

              target.define_method "around_#{transition}" do |&block|
                callback_state_machine_target.register_transition_callback(
                  :around, transition:
                ) do |state_machine:, **args, &do_transition_block|
                  block.call(command: state_machine.owner, **args, &do_transition_block)
                end
              end
            end
          end
        end

        private

        def callback_state_machine_target
          state_machine
        end
      end
    end
  end
end
