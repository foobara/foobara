module Foobara
  class Domain
    module OrganizationModuleExtension
      def foobara_organization
        @foobara_organization ||= Organization.new(organization_name: Util.non_full_name(self))
      end

      def foobara_organization?
        true
      end

      foobara_delegate :depends_on, to: :foobara_organization
    end
  end
end
