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

      def detached_entities
        @detached_entities ||= models.select(&:detached_entity?)
      end

      def entities
        @entities ||= detached_entities.select(&:entity?)
      end

      def models
        @models ||= types.select(&:model?).reject(&:builtin?)
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
