module Foobara
  module Callback
    class AbstractRegistry
      attr_accessor :callbacks

      def initialize
        self.callbacks = {}
      end

      def register_callback(_type, *_args, **_opts, &)
        raise "subclass responsibility"
      end

      def callbacks_for(_type, *_args, **_opts)
        raise "subclass_responsibility"
      end

      def before(*args, **opts, &)
        register_callback(:before, *args, **opts, &)
      end

      def after(*args, **opts, &)
        register_callback(:after, *args, **opts, &)
      end

      def around(*args, **opts, &)
        register_callback(:around, *args, **opts, &)
      end

      # these two seem to have awkward names
      def failure(*args, **opts, &)
        register_callback(:failure, *args, **opts, &)
      end

      def error(*args, **opts, &)
        register_callback(:error, *args, **opts, &)
      end

      def has_callbacks?(type, *args, **opts)
        callbacks_for(type, *args, **opts).present?
      end

      def has_before_callbacks?(*args, **opts)
        has_callbacks?(:before, *args, **opts)
      end

      def has_after_callbacks?(*args, **opts)
        has_callbacks?(:after, *args, **opts)
      end

      def has_around_callbacks?(*args, **opts)
        has_callbacks?(:around, *args, **opts)
      end

      def has_error_callbacks?(*args, **opts)
        has_callbacks?(:error, *args, **opts)
      end

      def has_failure_callbacks?(*args, **opts)
        has_callbacks?(:failure, *args, **opts)
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
