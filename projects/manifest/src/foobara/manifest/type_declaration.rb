require_relative "base_manifest"

module Foobara
  module Manifest
    class TypeDeclaration < BaseManifest
      def type_declaration_manifest
        relevant_manifest
      end

      def entity?
        relevant_manifest.size == 1 && find_type(self).entity?
      end
    end
  end
end
