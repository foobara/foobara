require_relative "base_manifest"

module Foobara
  module Manifest
    class TypeDeclaration < BaseManifest
      class << self
        def new(root_manifest, path)
          type_declaration = super(root_manifest, path)

          if self == TypeDeclaration && type_declaration.type.to_sym == :attributes
            Attributes.new(type_declaration.root_manifest, type_declaration.path)
          else
            type_declaration
          end
        end
      end

      def type_declaration_manifest
        relevant_manifest
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
