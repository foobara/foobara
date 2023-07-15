module Foobara
  class Command
    module Callbacks
      extend ActiveSupport::Concern

      class_methods do
        def callback_state_machine_target
          StateMachine
        end
      end

      def initialize(*)
        super
      end

      def callback_state_machine_target
        state_machine
      end

      Foobara::Command::StateMachine.transitions.each do |transition|
        [self, self.class].each do |target|
          %i[before after].each do |type|
            target.define_method "#{type}_#{transition}" do |&block|
              callback_state_machine_target.register_transition_callback(type, transition:) do |state_machine:, **_|
                block.call(command: state_machine.owner)
              end
            end
          end

          target.define_method "around_#{transition}" do |&block|
            callback_state_machine_target.register_transition_callback(
              :around)
            do |do_transition_block, state_machine:, **_|
              block.call(do_transition_block, command: state_machine.owner)
            end
          end

          %i[failure error].each do |type|
            target.define_method "#{type}_any_transition" do |&block|
              callback_state_machine_target.register_transition_callback(type) do |state_machine:|
                block.call(command: state_machine.owner)
              end
            end
          end
        end
      end
    end
  end
end
