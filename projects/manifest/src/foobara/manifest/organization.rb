module Foobara
  module Manifest
    class Organization < BaseManifest
      def organization_manifest
        relevant_manifest
      end

      def domains
        @domains ||= DataPath.value_at(:domains, organization_manifest).keys.map do |key|
          Domain.new(root_manifest, [*path, :domains, key])
        end
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
    end
  end
end
