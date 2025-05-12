require_relative "../desugarizer"

module Foobara
  class CommandConnector
    module Desugarizers
      class SymbolsToTrue < Desugarizer
        def applicable?(args_and_opts)
          args, _opts = args_and_opts
          args.size > 1
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts

          command_class, *symbols = args

          new_opts = {}

          symbols.each do |arg|
            if arg.is_a?(::Symbol)
              new_opts[arg] = true
            else
              # :nocov:
              raise "Was not expecting non-symbol arg: #{arg}"
              # :nocov:
            end
          end

          [[command_class], opts.merge(new_opts)]
        end

        def priority
          Priority::FIRST
        end
      end
    end
  end
end
