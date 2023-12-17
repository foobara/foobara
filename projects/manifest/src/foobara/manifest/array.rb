require_relative "type_declaration"

module Foobara
  module Manifest
    class Array < TypeDeclaration
      alias array_manifest relevant_manifest

      def element_type
        @element_type ||= TypeDeclaration.new(root_manifest, [*path, :element_type_declaration])
      end
    end
  end
end
