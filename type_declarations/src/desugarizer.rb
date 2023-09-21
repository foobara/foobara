require "foobara/type_declarations/with_registries"

module Foobara
  module TypeDeclarations
    class Desugarizer < Value::Transformer
      include WithRegistries

      class << self
        def requires_declaration_data?
          false
        end

        def manifest
          # :nocov:
          super.merge(processor_type: :desugarizer)
          # :nocov:
        end
      end

      def transform(value)
        desugarize(value)
      end
    end
  end
end
