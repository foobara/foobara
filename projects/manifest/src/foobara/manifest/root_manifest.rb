module Foobara
  module Manifest
    class RootManifest < BaseManifest
      include TruncatedInspect

      attr_accessor :root_manifest

      def initialize(root_manifest)
        super(root_manifest, [])
      end

      def organizations
        @organizations ||= DataPath.value_at(:organization, root_manifest).keys.map do |reference|
          Organization.new(root_manifest, [:organization, reference])
        end
      end

      def domains
        @domains ||= DataPath.value_at(:domain, root_manifest).keys.map do |reference|
          Domain.new(root_manifest, [:domain, reference])
        end
      end

      def commands
        organizations.map(&:commands).flatten
      end

      def types
        @types ||= DataPath.value_at(:type, root_manifest).keys.map do |reference|
          Type.new(root_manifest, [:type, reference])
        end
      end

      def entities
        organizations.map(&:entities).flatten
      end

      def models
        organizations.map(&:models).flatten
      end

      def entity_by_name(name)
        type = type_by_name(name)

        raise "#{name} is not an entity" unless type.entity?

        type
      end

      def model_by_name(name)
        type = type_by_name(name)

        raise "#{name} is not a model" unless type.model?

        type
      end

      def type_by_name(name)
        Type.new(root_manifest, [:type, name])
      end

      def command_by_name(name)
        Command.new(root_manifest, [:command, name])
      end

      def domain_by_name(name)
        Domain.new(root_manifest, [:domain, name])
      end

      def organization_by_name(name)
        Organization.new(root_manifest, [:organization, name])
      end
    end
  end
end
