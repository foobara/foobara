module Foobara
  class Organization
    class AlreadyRegisteredOrganizationDependency < StandardError; end

    class << self
      def all
        @all ||= [global]
      end

      def global
        return @global if defined?(@global)

        @global = new(global: true)
      end

      def reset_all
        remove_instance_variable("@all") if instance_variable_defined?("@all")
        remove_instance_variable("@global") if instance_variable_defined?("@global")
      end
    end

    attr_accessor :domains, :organization_name, :is_global

    def initialize(organization_name: nil, global: false)
      self.is_global = global
      @domains = []

      unless global
        Organization.all << self

        if organization_name.blank?
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

      @organization_symbol = organization_name&.underscore&.to_sym
    end

    def owns_domain?(domain)
      domains.include?(domain)
    end

    def register_domain(domain)
      domain.organization = self
      @domains << domain
    end

    def manifest
      domains.map(&:manifest_hash).inject(:merge) || {}
    end

    def manifest_hash
      key = global? ? :global_organization : organization_name

      {
        key.to_sym => manifest
      }
    end
  end
end
