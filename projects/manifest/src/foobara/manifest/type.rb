module Foobara
  class Manifest
    class Type < BaseManifest
      def type_manifest
        relevant_manifest
      end

      def entity?
        base_type == "entity"
      end

      def name
        # TODO: reverse these so we can splat the path if we want.
        DataPath.value_at(%i[declaration_data name], type_manifest)
      end
    end
  end
end
