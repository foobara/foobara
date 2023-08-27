module Foobara
  module Callback
    module Registry
      class Base
        def runner(*, **)
          Runner.new(unioned_callback_set_for(*, **))
        end

        def register_callback(type, *, **, &callback_block)
          unless block_given?
            # :nocov:
            raise ArgumentError, "Must provide a callback block to register"
            # :nocov:
          end

          validate_type!(type)

          set = specific_callback_set_for(*, **)

          set[type] << Block.for(type, callback_block)
        end

        def specific_callback_set_for(*_args, **_opts)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def unioned_callback_set_for(*_args, **_opts)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def before(...)
          register_callback(:before, ...)
        end

        def after(...)
          register_callback(:after, ...)
        end

        def around(...)
          register_callback(:around, ...)
        end

        def error(...)
          register_callback(:error, ...)
        end

        def has_callbacks?(type, *, **)
          unioned_callback_set_for(*, **)[type].present?
        end

        def has_before_callbacks?(*, **)
          has_callbacks?(:before, *, **)
        end

        def has_after_callbacks?(*, **)
          has_callbacks?(:after, *, **)
        end

        def has_around_callbacks?(*, **)
          has_callbacks?(:around, *, **)
        end

        def has_error_callbacks?(*, **)
          has_callbacks?(:error, *, **)
        end

        private

        def validate_type!(type)
          unless Block.types.include?(type)
            # TODO: raise a real error
            # :nocov:
            raise "bad type #{type} expected one of #{Block.types}"
            # :nocov:
          end
        end
      end
    end
  end
end
