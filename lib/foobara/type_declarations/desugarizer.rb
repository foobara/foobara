module Foobara
  module TypeDeclarations
    class Desugarizer < Value::Transformer
      def desugarize(_value)
        raise "subclass responsibility"
      end

      def transform(value)
        desugarize(value)
      end
    end
  end
end
