module Foobara
  class Entity < Model
    module Concerns
      module Callbacks
        include Concern

        # owner helps with determining the relevant object when running class-registered state transition callbacks
        attr_accessor :callback_registry

        def initialize(...)
          self.callback_registry = Callback::Registry::ChainedMultipleAction.new(self.class.class_callback_registry)
          super
        end

        # TODO: support passing multiple actions here
        def fire(action, data = {})
          callback_registry.runner(action).callback_data(data.merge(record: self, action:)).run
        end

        def without_callbacks
          old_callbacks_enabled = @callbacks_disabled

          begin
            @callbacks_disabled = true
            yield
          ensure
            @callbacks_disabled = old_callbacks_enabled
          end
        end

        foobara_delegate :register_callback, to: :callback_registry

        module ClassMethods
          def subclass_defined_callbacks
            @subclass_defined_callbacks ||= Foobara::Callback::Registry::SingleAction.new
          end

          def inherited(subclass)
            super

            subclass_defined_callbacks.runner.callback_data(subclass).run
          end

          def after_subclass_defined(&)
            subclass_defined_callbacks.register_callback(:after, &)
          end

          def class_callback_registry
            @class_callback_registry ||= begin
              actions = %i[
                initialized
                initialized_built
                initialized_thunk
                initialized_loaded
                initialized_created
                dirtied
                undirtied
                attribute_changed
                reverted
                loaded
                persisted
                hard_deleted
                unhard_deleted
                invalidated
                uninvalidated
              ]

              if self == Entity
                Callback::Registry::MultipleAction.new(actions).tap do |registry|
                  registry.allowed_types = [:after]
                end
              else
                Callback::Registry::ChainedMultipleAction.new(superclass.class_callback_registry)
              end
            end
          end

          foobara_delegate :register_callback, :possible_actions, to: :class_callback_registry
        end

        on_include do
          class_callback_registry.allowed_types.each do |type|
            [self, singleton_class].each do |target|
              method_name = "#{type}_any_action"

              target.define_method method_name do |&block|
                register_callback(type, nil, &block)
              end
            end

            possible_actions.each do |action|
              method_name = "#{type}_#{action}"

              [self, singleton_class].each do |target|
                target.define_method method_name do |&block|
                  register_callback(type, action, &block)
                end
              end
            end
          end
        end
      end
    end
  end
end
