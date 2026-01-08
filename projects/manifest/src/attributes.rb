require_relative "type_declaration"

module Foobara
  module Manifest
    class Attributes < TypeDeclaration
      optional_keys :required, :defaults, :element_type_declarations

      alias attributes_manifest relevant_manifest

      def required?(attribute_name)
        required = DataPath.value_at(:required, attributes_manifest)

        if required
          required.include?(attribute_name.to_sym) || required.include?(attribute_name.to_s)
        end
      end

      def default_for(attribute_name)
        DataPath.value_at([:defaults, attribute_name], attributes_manifest)
      end

      def has_attribute_declarations?
        !element_type_declarations.nil?
      end

      def attribute_declarations
        element_type_declarations.keys.to_h do |attribute_name|
          [
            attribute_name.to_sym,
            TypeDeclaration.new(root_manifest, [*manifest_path, :element_type_declarations, attribute_name])
          ]
        end
      end

      def empty?
        attribute_declarations.empty?
      end

      def attribute_names
        attribute_declarations.keys.map(&:to_s)
      end
    end
  end
end
