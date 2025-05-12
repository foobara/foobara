module Foobara
  class CommandConnector
    module Desugarizers
      # TODO: Make this the default. Deprecate :allowed_rule
      class AllowIf < Desugarizer
        def applicable?(args_and_opts)
          _args, opts = args_and_opts
          opts.key?(:allow_if)
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts

          opts = opts.dup

          opts[:allowed_rule] = opts.delete(:allow_if)

          [args, opts]
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
