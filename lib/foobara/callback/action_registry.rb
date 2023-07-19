module Foobara
  module Callback
    class Registry
      attr_accessor :callbacks, :possible_actions

      class InvalidAction < StandardError; end

      def initialize(*possible_actions)
        if possible_actions.length == 1 && possible_actions.first.is_a?(Array)
          possible_actions = possible_actions.first
        end

        self.possible_actions = possible_actions.map(&:to_s).sort.map(&:to_sym)
        self.callbacks = {}
      end

      def register_callback(type, action, &callback_block)
        validate_type!(type)
        validate_action!(action)

        required_non_keyword_arity = callback_block.parameters.count { |(param_type, _name)| param_type == :req }

        if type == :around
          # must have exactly one non-keyword required parameter to accept the do_it proc
          if required_non_keyword_arity != 1
            raise "around callbacks must take exactly one argument which will be the do_it proc"
          end
        elsif required_non_keyword_arity != 0
          raise "#{type} callback should take exactly 0 arguments"
        end

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

      def before(action, &)
        register_callback(:before, action, &)
      end

      def after(action, &)
        register_callback(:after, action, &)
      end

      def around(action, &)
        register_callback(:around, action, &)
      end

      # these two seem to have awkward names
      def failure(action, &)
        register_callback(:failure, action, &)
      end

      def error(action, &)
        register_callback(:error, action, &)
      end

      def has_callbacks?(type, action)
        callbacks_for(type, action).present?
      end

      def has_before_callbacks?(action)
        has_callbacks?(:before, action)
      end

      def has_after_callbacks?(action)
        has_callbacks?(:after, action)
      end

      def has_around_callbacks?(action)
        has_callbacks?(:around, action)
      end

      def has_error_callbacks?(action)
        has_callbacks?(:error, action)
      end

      def has_failure_callbacks?(action)
        has_callbacks?(:failure, action)
      end

      private

      def validate_type!(type)
        unless ALLOWED_CALLBACK_TYPES.include?(type)
          raise "bad type #{type} expected one of #{ALLOWED_CALLBACK_TYPES}"
        end
      end

      def validate_action!(action)
        if !action.nil? && !action.is_a?(Symbol)
          raise InvalidAction,
                "Invalid condition value #{condition_value}: expected Symbol or nil but got #{condition_value.class}"
        end
      end
    end
  end
end
