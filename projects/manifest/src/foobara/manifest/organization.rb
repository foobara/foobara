module Foobara
  module Manifest
    class Organization < BaseManifest
      self.category_symbol = :organization

      def organization_manifest
        relevant_manifest
      end

      def domains
        @domains ||= DataPath.value_at(:domains, organization_manifest).map do |key|
          Domain.new(root_manifest, [:domain, key])
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

      def models
        domains.map(&:models).flatten
      end

      def global?
        reference == "global_organization"
      end
    end
  end
end
