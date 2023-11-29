module Foobara
  class Manifest
    attr_accessor :root_manifest

    def initialize(root_manifest)
      self.root_manifest = root_manifest
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

    #
    # global_manifest.organizations.each_value do |organization_manifest|
    #   organization_manifests.push(organization_manifest)
    #
    #   organization_manifest.domains.each_value do |domain_manifest|
    #     domain_manifests.push(domain_manifest)
    #
    #     domain_manifest.commands.each_value do |command_manifest|
    #       command_manifests.push(command_manifest)
    #     end
    #
    #     domain_manifest.types.each_value do |type_manifest|
    #       entity_manifests.push(type_manifest) if is_entity_manifest(type_manifest)
    #     end
    #   end
    # end
  end
end
