module Foobara
  module Manifest
    class Error < BaseManifest
      def error_manifest
        relevant_manifest
      end

      def symbol
        super.to_sym
      end
    end
  end
end
