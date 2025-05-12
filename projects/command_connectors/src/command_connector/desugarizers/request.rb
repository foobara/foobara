module Foobara
  class CommandConnector
    module Desugarizers
      # TODO: Make this the default. Deprecate :request_mutators
      class Request < Desugarizer
        def applicable?(args_and_opts)
          _args, opts = args_and_opts
          opts.key?(:request)
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts
          [args, opts.merge(request_mutators: opts.delete(:request))]
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
