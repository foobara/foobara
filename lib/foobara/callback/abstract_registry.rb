module Foobara
  module Callback
    class AbstractRegistry
      def execute_with_callbacks(callback_data:, lookup_args: [], lookup_opts: {}, &do_it)
        callback_set = unioned_callback_set_for(*lookup_args, **lookup_opts)

        callback_set.execute_with_callbacks(callback_data, &do_it)
      end

      def runner(*args, **opts)
        Runner.new(unioned_callback_set_for(*args, **opts))
      end

      def register_callback(type, *args, **opts, &callback_block)
        validate_type!(type)
        validate_block!(type, callback_block)

        set = specific_callback_set_for(*args, **opts)

        argument_count = callback_block.parameters.count
        ending_keyword_count = ending_keyword_argument_count(callback_block)
        positional_argument_count = argument_count - ending_keyword_count

        set[type] << if ending_keyword_count > 0
                       proc do |*args|
                         positional_args = args[0...positional_argument_count]
                         keyword_args = args[positional_argument_count..].reduce(:merge)

                         callback_block.call(*positional_args, **keyword_args)
                       end
                     else
                       callback_block
                     end
      end

      def ending_keyword_argument_count(block)
        count = 0

        block.parameters.reverse.each do |(type, _name)|
          if %i[keyreq keyrest].include?(type)
            count += 1
          else
            break
          end
        end

        count
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

        if callback_block.parameters.any? { |(type, _name)| type == :block }
          raise "callback block can't take a block"
        end

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
