require_relative "multiple_action"

module Foobara
  module Callback
    module Registry
      class ChainedMultipleAction < MultipleAction
        attr_accessor :other_multiple_actions_registry

        class InvalidConditions < StandardError; end

        def possible_actions
          other_multiple_actions_registry.possible_actions
        end

        def allowed_types
          other_multiple_actions_registry.allowed_types
        end

        def initialize(other_multiple_actions_registry)
          self.other_multiple_actions_registry = other_multiple_actions_registry
          super(possible_actions)
        end

        def unioned_callback_set_for(...)
          super.union(other_multiple_actions_registry.unioned_callback_set_for(...))
        end
      end
    end
  end
end
