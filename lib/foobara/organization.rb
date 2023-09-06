module Foobara
  class Organization
    class AlreadyRegisteredOrganizationDependency < StandardError; end

    class << self
      def all
        @all ||= []
      end
    end

    attr_accessor :domains, :organization_name

    def initialize(organization_name:)
      self.organization_name = organization_name
      Organization.all << self
      @domains = []
    end

    def organization_symbol
      @organization_symbol ||= organization_name.underscore.to_sym
    end

    def owns_domain?(domain)
      domains.include?(domain)
    end

    def register_domain(domain)
      domain.organization = self
      @domains << domain
    end

    class << self
      def reset_all
        @all = nil
      end
    end
  end
end
