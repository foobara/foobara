require_relative "../desugarizer"

module Foobara
  module CommandConnectors
    module Desugarizers
      class SetInputs < Desugarizer
        def applicable?(args_and_opts)
          _args, opts = args_and_opts

          return false unless opts.key?(:inputs_transformers)

          transformers = opts[:inputs_transformers]
          transformers = Util.array(transformers)

          transformers.any? do |transformer|
            transformer.is_a?(::Hash) && transformer.key?(:set)
          end
        end

        def desugarize(args_and_opts)
          args, opts = args_and_opts

          transformers = opts[:inputs_transformers]
          is_array = transformers.is_a?(::Array)

          transformers = Util.array(transformers)

          transformers = transformers.map do |transformer|
            if transformer.is_a?(::Hash) && transformer.key?(:set)
              AttributesTransformers.set(transformer[:set])
            else
              # TODO: add a test for this
              # :nocov:
              transformer
              # :nocov:
            end
          end

          transformers = transformers.first unless is_array

          opts = opts.merge(inputs_transformers: transformers)

          [args, opts]
        end
      end
    end
  end
end
