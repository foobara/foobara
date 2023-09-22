Foobara.require_file("entity", "model")

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

        delegate :register_callback, to: :callback_registry

        module ClassMethods
          def class_callback_registry
            @class_callback_registry ||= Callback::Registry::MultipleAction.new(
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
            ).tap do |registry|
              registry.allowed_types = [:after]
            end
          end

          delegate :register_callback, :possible_actions, to: :class_callback_registry
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
