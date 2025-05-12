module Foobara
  class CommandConnector
    module Desugarizers
      # TODO: Make this the default. Deprecate :inputs_transformers
      class Inputs < Desugarizer
        def applicable?(args_and_opts)
          _args, opts = args_and_opts
          opts.key?(:inputs)
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts
          [args, opts.merge(inputs_transformers: opts.delete(:inputs))]
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
