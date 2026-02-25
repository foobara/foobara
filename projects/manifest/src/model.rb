require_relative "type"

module Foobara
  module Manifest
    class Model < Type
      class << self
        def associations(type, path = DataPath.new, result = {}, initial: true)
          if type.detached_entity? && !initial
            type = type.to_type if type.is_a?(TypeDeclaration)
            result[path.to_s] = type
          elsif type.model?
            type = type.to_type if type.is_a?(TypeDeclaration)
            associations(type.attributes_type, path, result, initial: false)
          elsif type.tuple?
            type = type.to_type_declaration_from_declaration_data if type.is_a?(Type)
            type.element_types&.each&.with_index do |element_type, index|
              associations(element_type, path.append(index), result, initial: false)
            end
          elsif type.array?
            type = type.to_type_declaration_from_declaration_data if type.is_a?(Type)
            element_type = type.element_type

            if element_type
              associations(element_type, path.append(:"#"), result, initial: false)
            end
          elsif type.attributes?
            type = type.to_type_declaration_from_declaration_data if type.is_a?(Type)
            type.attribute_declarations.each_pair do |attribute_name, element_type|
              associations(element_type, path.append(attribute_name), result, initial: false)
            end
          # :nocov:
          elsif type.associative_array?
            if contains_associations?(type)
              raise "Associative array types with associations in them are not currently supported. " \
                    "Use attributes type if you can or set the key_type and/or value_type to duck type"
            end
          end
          # :nocov:

          result
        end
      end

      self.category_symbol = :type

      optional_keys :delegates

      alias model_manifest relevant_manifest

      def attributes_type
        Attributes.new(root_manifest, [*manifest_path, :declaration_data, :attributes_declaration])
      end

      def guaranteed_to_exist?(attribute_name)
        return true if attributes_type.required?(attribute_name)

        guaranteed_to_exist = DataPath.value_at([:delegates, :guaranteed_to_exist], relevant_manifest)

        return false unless guaranteed_to_exist

        guaranteed_to_exist.include?(attribute_name.to_sym) || guaranteed_to_exist.include?(attribute_name.to_s)
      end

      def attribute_names
        attributes_type.attribute_names
      end

      def full_model_name
        scoped_full_name
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
