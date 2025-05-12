module Foobara
  class CommandConnector
    module Desugarizers
      # TODO: Make this the default. Deprecate :result_transformers
      class Result < Desugarizer
        def applicable?(args_and_opts)
          _args, opts = args_and_opts
          opts.key?(:result)
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts
          [args, opts.merge(result_transformers: opts.delete(:result))]
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
