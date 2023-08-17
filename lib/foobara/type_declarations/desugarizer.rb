require "foobara/type_declarations/with_registries"

module Foobara
  module TypeDeclarations
    class Desugarizer < Value::Transformer
      include WithRegistries

      def transform(value)
        desugarize(value)
      end
    end
  end
end
