module Foobara
  class CommandConnector
    module Desugarizers
      # TODO: Make this the default. Deprecate :response_mutators
      class Response < Desugarizer
        def applicable?(args_and_opts)
          _args, opts = args_and_opts
          opts.key?(:response)
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts
          [args, opts.merge(response_mutators: opts.delete(:response))]
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
