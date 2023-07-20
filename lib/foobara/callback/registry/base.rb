module Foobara
  module Callback
    module Registry
      class Base
        def execute_with_callbacks(callback_data:, lookup_args: [], lookup_opts: {}, &do_it)
          callback_set = unioned_callback_set_for(*lookup_args, **lookup_opts)

          callback_set.execute_with_callbacks(callback_data, &do_it)
        end

        def runner(*args, **opts)
          Runner.new(unioned_callback_set_for(*args, **opts))
        end

        def register_callback(type, *args, **opts, &callback_block)
          validate_type!(type)

          set = specific_callback_set_for(*args, **opts)

          set[type] << Block.for(type, callback_block)
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
          unless Block.types.include?(type)
            raise "bad type #{type} expected one of #{Block.types}"
          end
        end
      end
    end
  end
end
