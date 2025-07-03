module Foobara
  module Manifest
    class PossibleError < BaseManifest
      optional_key(:path, default: [])

      def possible_error_manifest
        relevant_manifest
      end

      def error
        Error.new(root_manifest, [:error, DataPath.value_at([:error], possible_error_manifest)])
      end

      def processor_manifest_data
        self[:processor_manifest_data]
      end

      def manually_added
        self[:manually_added]
      end

      # oops, shadowed the convenience method
      def _path
        method_missing(:path)
      end
    end
  end
end
