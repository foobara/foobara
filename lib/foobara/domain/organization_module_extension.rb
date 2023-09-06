require "foobara/organization"

module Foobara
  class Domain
    module OrganizationModuleExtension
      def foobara_organization
        @foobara_organization ||= Organization.new(organization_name: name.demodulize)
      end

      def foobara_organization?
        true
      end

      delegate :depends_on, to: :foobara_organization
    end
  end
end
