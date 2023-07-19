module Foobara
  module Callback
    class ActionRegistry < AbstractRegistry
      attr_accessor :possible_actions

      class InvalidAction < StandardError; end

      def initialize(*possible_actions)
        super()

        if possible_actions.length == 1 && possible_actions.first.is_a?(Array)
          possible_actions = possible_actions.first
        end

        self.possible_actions = possible_actions.map(&:to_s).sort.map(&:to_sym)
      end

      def register_callback(type, action, &callback_block)
        validate_type!(type)
        validate_action!(action)
        validate_block!(type, callback_block)

        callbacks_for_action = callbacks[type] ||= {}
        callback_blocks = callbacks_for_action[action] ||= []

        callback_blocks << callback_block
      end

      def callbacks_for(type, action)
        validate_type!(type)
        validate_action!(action)

        callbacks_for_type = callbacks[type]

        return [] if callbacks_for_type.blank?

        callbacks_for_any = callbacks_for_type[nil]
        callbacks_for_action = if action
                                 callbacks_for_type[action]
                               end

        [*callbacks_for_action, *callbacks_for_any].compact
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
