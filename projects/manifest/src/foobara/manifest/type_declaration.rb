require_relative "base_manifest"

module Foobara
  module Manifest
    class TypeDeclaration < BaseManifest
      optional_keys(:allow_nil, :one_of, :sensitive, :sensitive_exposed)

      class << self
        def new(root_manifest, path)
          type_declaration = super

          if self == TypeDeclaration
            case type_declaration.type.to_sym
            when :attributes
              Attributes.new(type_declaration.root_manifest, type_declaration.path)
            when :array
              Array.new(type_declaration.root_manifest, type_declaration.path)
            else
              type_declaration
            end
          else
            type_declaration
          end
        end
      end

      def sensitive?
        sensitive || sensitive_exposed
      end

      # rubocop:disable Naming/MemoizedInstanceVariableName
      # TODO: create an Attribute class to encapsulate this situation
      def attribute?
        return @is_attribute if defined?(@is_attribute)

        parent_path_atom = path[2..][-2]
        @is_attribute = [:element_type_declarations, "element_type_declarations"].include?(parent_path_atom)
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName

      def parent_attributes
        return @parent_attributes if defined?(@parent_attributes)

        raise "Not an attribute" unless attribute?

        @parent_attributes = Attributes.new(root_manifest, path[0..-3])
      end

      def attribute_name
        return @attribute_name if defined?(@attribute_name)

        raise "Not an attribute" unless attribute?

        @attribute_name = path[-1]
      end

      def required?
        parent_attributes.required?(attribute_name)
      end

      def default
        parent_attributes.default_for(attribute_name)
      end

      def allows_nil?
        allow_nil
      end

      def type_declaration_manifest
        relevant_manifest
      end

      def attributes?
        type.to_sym == :attributes
      end

      def array?
        type.to_sym == :array
      end

      def model?
        return @model if defined?(@model)

        @model = to_type.model?
      end

      def custom?
        return @custom if defined?(@custom)

        @custom = to_type.custom?
      end

      def to_model
        raise "not an model" unless model?
        raise "model extension instead of an model" unless relevant_manifest.size == 1

        type = to_type

        raise "not an model" unless type.model?

        type
      end

      def detached_entity?
        return @detached_entity if defined?(@detached_entity)

        @detached_entity = to_type.detached_entity?
      end

      def to_detached_entity
        raise "not an detached_entity" unless detached_entity?
        raise "detached_entity extension instead of an detached_entity" unless relevant_manifest.size == 1

        type = to_type

        raise "not an detached_entity" unless type.detached_entity?

        type
      end

      def entity?
        return @entity if defined?(@entity)

        @entity = to_type.entity?
      end

      def to_entity
        raise "not an entity" unless entity?
        raise "entity extension instead of an entity" unless relevant_manifest.size == 1

        type = to_type

        raise "not an entity" unless type.entity?

        type
      end

      def to_type
        # awkward??
        @to_type ||= find_type(self)
      end
    end
  end
end
