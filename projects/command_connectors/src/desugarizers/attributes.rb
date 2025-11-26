require_relative "../desugarizer"

module Foobara
  module CommandConnectors
    module Desugarizers
      class Attributes < Desugarizer
        def desugarizer_symbol
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def opts_key
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def applicable?(args_and_opts)
          _args, opts = args_and_opts

          return false unless opts.key?(opts_key)

          transformers = opts[opts_key]
          transformers = Util.array(transformers)

          transformers.any? do |transformer|
            transformer.is_a?(::Hash) && transformer.key?(desugarizer_symbol)
          end
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts

          transformers = opts[opts_key]
          is_array = transformers.is_a?(::Array)

          transformers = Util.array(transformers)

          transformers = transformers.map do |transformer|
            if transformer.is_a?(::Hash) && transformer.key?(desugarizer_symbol)
              params = transformer[desugarizer_symbol]
              AttributesTransformers.send(transformer_method, *params)
            else
              transformer
            end
          end

          transformers = transformers.first unless is_array

          opts = opts.merge(opts_key => transformers)

          [args, opts]
        end

        def transformer_method
          desugarizer_symbol
        end
      end
    end
  end
end
