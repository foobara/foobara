require_relative "type_declaration"

module Foobara
  module Manifest
    class Tuple < TypeDeclaration
      alias tuple_manifest relevant_manifest

      def element_types
        @element_types ||= (0...element_type_declarations.size).map do |index|
          TypeDeclaration.new(root_manifest, [*manifest_path, :element_type_declarations, index])
        end
      end
    end
  end
end
