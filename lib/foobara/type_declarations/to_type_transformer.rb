require "foobara/type_declarations/with_registries"

module Foobara
  module TypeDeclarations
    class ToTypeTransformer < Value::Transformer
      include WithRegistries

      def always_applicable?
        true
      end
    end
  end
end
