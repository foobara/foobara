module Foobara
  module CommandConnectors
    module Desugarizers
      class Auth < Desugarizer
        def applicable?(args_and_opts)
          args_and_opts.last.key?(:auth)
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts

          opts = opts.dup
          auth = opts.delete(:auth)

          [args, opts.merge(requires_authentication: auth)]
        end
      end
    end
  end
end
