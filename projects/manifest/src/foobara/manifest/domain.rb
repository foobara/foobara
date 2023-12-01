module Foobara
  module Manifest
    class Domain < BaseManifest
      def domain_manifest
        relevant_manifest
      end

      def commands
        @commands ||= DataPath.value_at(:commands, domain_manifest).keys.map do |key|
          Command.new(root_manifest, [*path, :commands, key])
        end
      end

      def types
        @types ||= DataPath.value_at(:types, domain_manifest).keys.map do |key|
          Type.new(root_manifest, [*path, :types, key])
        end
      end

      def entities
        @entities ||= types.select(&:entity?)
      end
    end
  end
end
