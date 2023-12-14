module Foobara
  module Manifest
    class Domain < BaseManifest
      def domain_manifest
        relevant_manifest
      end

      def commands
        @commands ||= DataPath.value_at(:commands, domain_manifest).map do |key|
          Command.new(root_manifest, [:command, key])
        end
      end

      def types
        @types ||= DataPath.value_at(:types, domain_manifest).map do |key|
          Type.new(root_manifest, [:type, key])
        end
      rescue => e
        binding.pry
        raise
      end

      def entities
        @entities ||= types.select(&:entity?)
      end

      def domain
        self
      end
    end
  end
end
