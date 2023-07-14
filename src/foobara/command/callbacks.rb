module Foobara
  class Command
    module Callbacks
      extend ActiveSupport::Concern

      def initialize(*)
        super
        setup_callbacks
      end

      # TODO: maybe support class-level callbacks in state machine so we don't do this in two places here
      def setup_callbacks
        self.class.callbacks.each_pair do |type, transition_map|
          transition_map.each_pair do |transition, blocks|
            blocks.each do |block|
              state_machine.register_transition_callback(type, transition:) do
                block.call(self)
              end
            end
          end
        end
      end

      Foobara::Command::StateMachine.transitions.each do |transition|
        %i[before after around].each do |type|
          define_method "#{type}_#{transition}" do |&block|
            state_machine.register_transition_callback(type, transition) do
              block.call(self)
            end
          end
        end

        %i[failure error].each do |type|
          define_method "#{type}_any_transition" do |&block|
            state_machine.register_transition_callback(type) do
              block.call(self)
            end
          end
        end
      end

      class_methods do
        def callbacks
          @callbacks ||= {}
        end

        %i[before after around].each do |type|
          Foobara::Command::StateMachine.transitions.each do |transition|
            define_method "#{type}_#{transition}" do |&block|
              add_callback(type, transition, block)
            end
          end
        end

        %i[failure error].each do |type|
          define_method "#{type}_any_transition" do |&block|
            state_machine.register_transition_callback(type) do
              add_callback(type, nil, block)
            end
          end
        end

        def add_callback(type, transition, block)
          type = type.to_sym
          transition = transition&.to_sym

          type_callbacks = callbacks[type] ||= {}
          transition_callbacks = type_callbacks[transition] ||= []
          transition_callbacks << block
        end
      end
    end
  end
end
