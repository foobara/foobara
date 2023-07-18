require "foobara/command/state_machine"

module Foobara
  class Command
    module Concerns
      module Callbacks
        extend ActiveSupport::Concern

        class_methods do
          def code_callbacks
            @code_callbacks ||= Foobara::Callback::Registry.new(:state)
          end

          def inherited(subclass)
            super
            return unless code_callbacks.has_callbacks?(:after, state: :subclass_defined)

            TracePoint.trace(:end) do |tp|
              # we really shouldn't have to do this for the singleton class...
              # this unfortunately comes up in the test suite
              # TODO: figure out a solution to this even if it's not using anonymous classes in the test suitegitk
              if tp.self == subclass || tp.self == subclass.singleton_class
                tp.disable
                Foobara::Command.run_defined_callbacks(subclass)
              end
            end
          end

          def after_subclass_defined(&)
            code_callbacks.register_callback(:after, state: :subclass_defined, &)
          end

          def run_defined_callbacks(subclass)
            code_callbacks.callbacks_for(:after, state: :subclass_defined).each do |callback|
              callback.call(subclass)
            end
          end

          def callback_state_machine_target
            Foobara::Command::StateMachine
          end

          delegate :remove_all_callbacks, to: :callback_state_machine_target
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
                :around
              ) do |do_transition_block, state_machine:, **_|
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

        private

        def callback_state_machine_target
          state_machine
        end
      end
    end
  end
end
