module Foobara
  module Callback
    class AbstractRegistry
      # how to specify payload to callbacks??
      def execute_with_callbacks(callback_data:, lookup_args: [], lookup_opts: {}, &do_it)
        callback_set = unioned_callback_set_for(*lookup_args, **lookup_opts)

        if block_given?
          callback_set.each_before do |callback|
            callback.call(**callback_data)
          end

          begin
            callback_set.around.inject(do_it) do |nested_proc, callback|
              proc do
                callback.call(nested_proc, **callback_data)
              end
            end.call(**callback_data)
          rescue => e
            # TODO: should we support error and failure callbacks?
            # I guess let's just do error for now in case of yagni
            callback_set.each_error do |callback|
              callback.call(e, **callback_data)
            end

            raise
          end
        else
          # TODO: raise better errors
          raise if has_before_callbacks?(*lookup_args, **lookup_opts)
          raise if has_around_callbacks?(*lookup_args, **lookup_opts)
        end

        callback_set.each_after do |callback|
          callback.call(callback_data)
        end
      end

      def register_callback(type, *args, **opts, &callback_block)
        validate_type!(type)
        validate_block!(type, callback_block)

        set = specific_callback_set_for(*args, **opts)

        set[type] << callback_block
      end

      def specific_callback_set_for(*_args, **_opts)
        raise "subclass responsibility"
      end

      def unioned_callback_set_for(*_args, **_opts)
        raise "subclass responsibility"
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

      def error(*args, **opts, &)
        register_callback(:error, *args, **opts, &)
      end

      def has_callbacks?(type, *args, **opts)
        unioned_callback_set_for(*args, **opts)[type].present?
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
