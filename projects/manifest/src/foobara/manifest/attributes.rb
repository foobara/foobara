require_relative "type_declaration"

module Foobara
  module Manifest
    class Attributes < TypeDeclaration
      optional_key :required

      alias attribute_manifest relevant_manifest

      def required?(attribute_name)
        required = DataPath.value_at(:required, attribute_manifest)

        if required
          required.include?(attribute_name.to_sym) || required.include?(attribute_name.to_s)
        end
      end

      def attribute_declarations
        element_type_declarations.keys.to_h do |attribute_name|
          [
            attribute_name.to_sym,
            TypeDeclaration.new(root_manifest, [*path, :element_type_declarations, attribute_name])
          ]
        end
      end
    end
  end
end