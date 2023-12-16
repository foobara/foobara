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

      def error_name
        scoped_name
      end
    end
  end
end
