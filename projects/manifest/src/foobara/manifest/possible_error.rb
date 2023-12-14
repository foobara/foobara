module Foobara
  module Manifest
    class PossibleError < BaseManifest
      def possible_error_manifest
        relevant_manifest
      end

      def error
        Error.new(root_manifest, [:error, possible_error_manifest["error"]])
      end

      # TODO: this has to die

      # oops, shadowed the convenience method
      def _path
        method_missing(:path)
      end
    end
  end
end
