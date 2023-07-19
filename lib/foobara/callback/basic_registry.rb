module Foobara
  module Callback
    class BasicRegistry
      attr_accessor :callbacks

      def initialize
        self.callbacks = {}
      end

      def register_callback(type, &callback_block)
        validate_type!(type)
        validate_block!(type, callback_block)

        callback_blocks = callbacks[type] ||= []

        callback_blocks << callback_block
      end

      def callbacks_for(type)
        validate_type!(type)

        callbacks[type].presence || []
      end

      def before(&)
        register_callback(:before,  &)
      end

      def after(&)
        register_callback(:after, &)
      end

      def around(&)
        register_callback(:around, &)
      end

      # these two seem to have awkward names
      def failure(&)
        register_callback(:failure, &)
      end

      def error(&)
        register_callback(:error, &)
      end

      def has_callbacks?(type)
        callbacks_for(type).present?
      end

      def has_before_callbacks?
        has_callbacks?(:before)
      end

      def has_after_callbacks?
        has_callbacks?(:after)
      end

      def has_around_callbacks?
        has_callbacks?(:around)
      end

      def has_error_callbacks?
        has_callbacks?(:error)
      end

      def has_failure_callbacks?
        has_callbacks?(:failure)
      end

      private

      def validate_type!(type)
        unless ALLOWED_CALLBACK_TYPES.include?(type)
          raise "bad type #{type} expected one of #{ALLOWED_CALLBACK_TYPES}"
        end
      end

      def validate_block!(type, callback_block)
        required_non_keyword_arity = callback_block.parameters.count { |(param_type, _name)| param_type == :req }

        if type == :around
          # must have exactly one non-keyword required parameter to accept the do_it proc
          if required_non_keyword_arity != 1
            raise "around callbacks must take exactly one argument which will be the do_it proc"
          end
        elsif required_non_keyword_arity != 0
          raise "#{type} callback should take exactly 0 arguments"
        end
      end
    end
  end
end
