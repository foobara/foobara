Foobara.require_project_file("type_declarations", "with_registries")

module Foobara
  module TypeDeclarations
    class Desugarizer < Value::Transformer
      include WithRegistries

      class << self
        def requires_declaration_data?
          false
        end

        def foobara_manifest(to_include: Set.new, remove_sensitive: false)
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
