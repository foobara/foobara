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
        if takes_block?(callback_block)
          if type != :around
            raise "#{type} callback block cannot accept a block"
          end
        elsif type == :around
          raise "Around callback must take a block argument to receive the do_it block"
        end

        if has_keyword_args?(callback_block)
          if type == :error
            raise "Expect error block to only receive one argument which is the UnexpectedErrorWhileRunningCallback. " \
                  "It cannot take keyword arguments."
          end

          if has_positional_args?(callback_block)
            raise "Callback block can't both accept keyword arguments and also a positional argument"
          end
        elsif !has_one_or_zero_positional_args?(callback_block)
          raise "Can't pass multiple arguments to a callback. Only 1 or 0 arguments."
        end
      end

      def validate_error_block!(callback_block)
        if takes_block?(callback_block)
          raise "callback block can't take a block"
        end
      end

      def takes_block?(callback_block)
        callback_block.parameters.last&.first&.==(:block)
      end

      def has_no_args_ignoring_block(callback_block)
        param_types_ignoring_block(callback_block).empty?
      end

      def has_one_or_zero_positional_args?(callback_block)
        positional_args_count(callback_block) <= 1
      end

      def has_one_positional_arg?(callback_block)
        positional_args_count(callback_block) == 1
      end

      def has_positional_args?(callback_block)
        !positional_args_count(callback_block).zero?
      end

      def has_keyword_args?(callback_block)
        param_types(callback_block).any? { |type| %i[keyreq keyrest].include?(type) }
      end

      def param_types_ignoring_block(callback_block)
        param_types(callback_block).reject { |type| type == :block }
      end

      def param_types(callback_block)
        callback_block.parameters.map(&:first)
      end

      def optional_positional_args_count(callback_block)
        callback_block.parameters.map(&:first).count { |type| type == :opt }
      end

      def required_positional_args_count(callback_block)
        callback_block.parameters.map(&:first).count { |type| type == :req }
      end

      def positional_args_count(callback_block)
        optional_positional_args_count(callback_block) + required_positional_args_count(callback_block)
      end
    end
  end
end
