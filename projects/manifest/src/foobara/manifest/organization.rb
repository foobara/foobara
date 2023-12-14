module Foobara
  module Manifest
    class Organization < BaseManifest
      def organization_manifest
        relevant_manifest
      end

      def domains
        @domains ||= DataPath.value_at(:domains, organization_manifest).map do |key|
          Domain.new(root_manifest, [:domain, key])
        end
      end

      def organization_name
        relevant_manifest["organization_name"] || relevant_manifest[:organization_name]
      end

      def commands
        domains.map(&:commands).flatten
      end

      def types
        domains.map(&:types).flatten
      end

      def entities
        domains.map(&:entities).flatten
      end

      def global?
        reference == "global_organization"
      end
    end
  end
end
