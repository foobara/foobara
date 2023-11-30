module Foobara
  module Manifest
    class Domain < BaseManifest
      def domain_manifest
        relevant_manifest
      end

      def commands
        @commands ||= DataPath.value_at(:commands, domain_manifest).map do |key, value|
          Command.new(root_manifest, [*path, :commands, key])
        end
      end

      def types
        @types ||= DataPath.value_at(:types, domain_manifest).map do |key, value|
          Type.new(root_manifest, [*path, :types, key])
        end
      end

      def entities
        @entities ||= types.select(&:entity?).map do |type|
          Entity.new(root_manifest, [*path, :types, type.entity_name])
        end
      end
    end
  end
end
