module Foobara
  module Manifest
    class Error < BaseManifest
      def error_manifest
        relevant_manifest
      end

      def symbol
        super.to_sym
      end

      # TODO: this has to die

      # oops, shadowed the convenience method
      def _path
        method_missing(:path)
      end
    end
  end
end
