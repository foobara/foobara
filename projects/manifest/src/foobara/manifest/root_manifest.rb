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
    end
  end
end
