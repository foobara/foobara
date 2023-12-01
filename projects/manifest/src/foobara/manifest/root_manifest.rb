module Foobara
  module Manifest
    class RootManifest < BaseManifest
      include TruncatedInspect

      attr_accessor :root_manifest

      def initialize(root_manifest)
        super(root_manifest, [])
      end

      def organizations
        @organizations ||= DataPath.value_at(:organizations, root_manifest).keys.map do |key|
          Organization.new(root_manifest, [:organizations, key])
        end
      end

      def domains
        organizations.map(&:domains).flatten
      end

      def commands
        organizations.map(&:commands).flatten
      end

      def types
        organizations.map(&:types).flatten
      end

      def entities
        organizations.map(&:entities).flatten
      end

      def entity_by_name(name)
        type = type_by_name(name)

        type if type.entity?
      end

      def type_by_name(name)
        type = types.select { |t| t.name.to_s == name.to_s }

        if type.empty?
          # :nocov:
          raise "No type found named #{name}"
          # :nocov:
        elsif type.size > 1
          # :nocov:
          raise "Name collision on type with #{name}: #{type.size} types found but expected 1"
          # :nocov:
        end

        type.first
      end

      def command_by_name(name)
        command = commands.select { |c| c.command_name.to_s == name.to_s }

        if command.empty?
          # :nocov:
          raise "No command found named #{name}"
          # :nocov:
        elsif command.size > 1
          # :nocov:
          raise "Name collision on command with #{name}: #{command.size} commands found but expected 1"
          # :nocov:
        end

        command.first
      end

      def domain_by_name(name)
        domain = domains.select { |d| d.domain_name.to_s == name.to_s }

        if domain.empty?
          # :nocov:
          raise "No domain found named #{name}"
          # :nocov:
        elsif domain.size > 1
          # :nocov:
          raise "Name collision on domain with #{name}: #{domain.size} domains found but expected 1"
          # :nocov:
        end

        domain.first
      end

      def organization_by_name(name)
        organization = organizations.select { |o| o.organization_name.to_s == name.to_s }

        if organization.empty?
          # :nocov:
          raise "No organization found named #{name}"
          # :nocov:
        elsif organization.size > 1
          # :nocov:
          raise "Name collision on organization with #{name}: #{organization.size} organizations found but expected 1"
          # :nocov:
        end

        organization.first
      end
    end
  end
end
