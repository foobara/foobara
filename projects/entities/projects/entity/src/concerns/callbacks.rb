require "foobara/callback"

module Foobara
  class Entity < DetachedEntity
    module Concerns
      module Callbacks
        include Concern

        class << self
          def reset_all
            Foobara.raise_if_production!("reset_all")
            Entity.instance_variable_set("@class_callback_registry", nil)
          end
        end

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

        def register_callback(...)
          callback_registry.register_callback(...)
        end

        module ClassMethods
          def class_callback_registry
            @class_callback_registry ||= begin
              actions = [
                :initialized,
                :initialized_built,
                :initialized_thunk,
                :initialized_loaded,
                :initialized_created,
                :dirtied,
                :undirtied,
                :attribute_changed,
                :reverted,
                :loaded,
                :persisted,
                :hard_deleted,
                :unhard_deleted,
                :invalidated,
                :uninvalidated
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

          def register_callback(...)
            class_callback_registry.register_callback(...)
          end

          def possible_actions
            class_callback_registry.possible_actions
          end
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
