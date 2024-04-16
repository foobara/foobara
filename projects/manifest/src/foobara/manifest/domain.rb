module Foobara
  module Manifest
    class Domain < BaseManifest
      self.category_symbol = :domain

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
      end

      def entities
        @entities ||= types.select(&:entity?)
      end

      def models
        @models ||= types.select(&:model?)
      end

      def global?
        reference == "global_organization::global_domain"
      end

      def domain_name
        scoped_name
      end

      def full_domain_name
        scoped_full_name
      end
    end
  end
end
