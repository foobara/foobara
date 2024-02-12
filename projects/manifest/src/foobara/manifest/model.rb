require_relative "type"

module Foobara
  module Manifest
    class Model < Type
      self.category_symbol = :type

      alias model_manifest relevant_manifest

      def attributes_type
        Attributes.new(root_manifest, [*path, :attributes_type])
      end

      def attribute_names
        attributes_type.attribute_names
      end

      # TODO: rename
      def has_associations?(type = attributes_type)
        case type
        when Entity
          true
        when Model
          has_associations?(type.attributes_type)
        when Attributes
          type.attribute_declarations.values.any? do |attribute_declaration|
            has_associations?(attribute_declaration)
          end
        when Array
          has_associations?(type.element_type)
        when TypeDeclaration
          has_associations?(type.to_type)
        when Type
          type.entity?
        else
          # :nocov:
          raise "not sure how to proceed with #{type}"
          # :nocov:
        end
      end
    end
  end
end
