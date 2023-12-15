module Foobara
  module Manifest
    class Error < BaseManifest
      self.category_symbol = :error

      def error_manifest
        relevant_manifest
      end

      def symbol
        super.to_sym
      end
    end
  end
end
