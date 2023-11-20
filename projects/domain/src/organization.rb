module Foobara
  class Organization
    class AlreadyRegisteredOrganizationDependency < StandardError; end

    class << self
      def all
        @all ||= [global]
      end

      def global
        return @global if defined?(@global)

        @global = new(global: true, mod: nil)
      end

      def reset_all
        remove_instance_variable("@all") if instance_variable_defined?("@all")
        remove_instance_variable("@global") if instance_variable_defined?("@global")
      end

      def [](name)
        name = name.to_s

        @all&.find do |org|
          org.organization_name == name
        end
      end

      def create(name)
        class_name = name.to_s

        mod = Module.new

        Object.const_set(class_name, mod)

        mod.foobara_organization!
        mod.foobara_organization
      end
    end

    attr_accessor :domains, :organization_name, :is_global, :mod

    def initialize(mod:, organization_name: nil, global: false)
      self.mod = mod
      self.is_global = global
      @domains = []

      unless global
        Organization.all << self

        if organization_name.nil? || organization_name.empty?
          # :nocov:
          raise ArgumentError, "Must provide an organization_name:"
          # :nocov:
        end

        self.organization_name = organization_name
      end
    end

    def global?
      is_global
    end

    def organization_symbol
      return @organization_symbol if defined?(@organization_symbol)

      @organization_symbol = Util.underscore_sym(organization_name)
    end

    def owns_domain?(domain)
      domains.include?(domain)
    end

    def register_domain(domain)
      domain.organization = self
      @domains << domain
    end

    def manifest
      {
        name: organization_name,
        domains: domains.map(&:manifest_hash).inject(:merge) || {}
      }
    end

    def manifest_hash
      key = global? ? :global_organization : organization_name

      {
        key.to_sym => manifest
      }
    end
  end
end
