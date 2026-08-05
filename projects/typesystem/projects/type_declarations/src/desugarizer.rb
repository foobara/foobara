require_relative "with_registries"

module Foobara
  module TypeDeclarations
    class Desugarizer < Value::Transformer
      include WithRegistries

      class << self
        def requires_declaration_data?
          false
        end

        def foobara_manifest
          # simplecov:disable
          super.merge(processor_type: :desugarizer)
          # simplecov:enable
        end
      end

      def transform(value)
        desugarize(value)
      end
    end
  end
end
