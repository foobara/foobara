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

    # Organization
    #   Domain
    #     Command
    #       input type
    #       possible errors
    #       result type
    #     type
    #       Error
    #
    def manifest
      {
        # TODO: do we really need symbols and names?? kill one of these...
        organization_name:,
        domains: domains.map(&:domain_name)
      }
    end

    class << self
      def reset_all
        @all = nil
      end
    end
  end
end
