module Foobara
  module CommandConnectors
    class Desugarizer < Value::Transformer
      class << self
        def requires_declaration_data?
          false
        end
      end

      def transform(value)
        desugarize(value)
      end

      # in case of tie, right wins, like with Hash#merge
      def merge(left, right)
        return left if right.nil?
        return right if left.nil?

        if left.is_a?(::Hash) && right.is_a?(::Hash)
          # TODO: remove :nocov: once we have an only: and/or reject: desugarizer with a test that
          # merges them together.
          # :nocov:
          left.merge(right)
          # :nocov:
        else
          Util.array(left) + Util.array(right)
        end
      end

      def rename(args_and_opts, sugar_name, official_name)
        args, opts = args_and_opts

        opts = opts.dup
        sugar = opts.delete(sugar_name)
        official = opts.delete(official_name)

        [
          args,
          opts.merge(official_name => merge(sugar, official))
        ]
      end
    end
  end
end
