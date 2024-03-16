require_relative "base_manifest"

module Foobara
  module Manifest
    class TypeDeclaration < BaseManifest
      optional_keys(:allow_nil, :one_of)

      class << self
        def new(root_manifest, path)
          type_declaration = super(root_manifest, path)

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

      def to_model
        raise "not an model" unless model?
        raise "model extension instead of an model" unless relevant_manifest.size == 1

        type = to_type

        raise "not an model" unless type.model?

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
