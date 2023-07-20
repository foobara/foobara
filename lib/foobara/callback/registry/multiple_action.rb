module Foobara
  module Callback
    module Registry
      class MultipleAction < Base
        attr_accessor :callback_sets, :possible_actions

        class InvalidAction < StandardError; end

        def initialize(*possible_actions)
          super()

          self.callback_sets = {}

          if possible_actions.length == 1 && possible_actions.first.is_a?(Array)
            possible_actions = possible_actions.first
          end

          self.possible_actions = possible_actions.map(&:to_s).sort.map(&:to_sym)
        end

        def specific_callback_set_for(action)
          validate_action!(action)
          callback_sets[action] ||= Callback::Set.new
        end

        def unioned_callback_set_for(action)
          set = specific_callback_set_for(nil)
          action ? set.union(specific_callback_set_for(action)) : set
        end

        private

        def validate_action!(action)
          if !action.nil? && !action.is_a?(Symbol)
            raise InvalidAction,
                  "Invalid condition value #{condition_value}: expected Symbol or nil but got #{condition_value.class}"
          end
        end
      end
    end
  end
end
