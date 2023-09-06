module Foobara
  class Domain
    module DomainModuleExtension
      def foobara_domain
        @foobara_domain ||= begin
          org_module = Util.module_for(self)

          organization = if org_module&.foobara_organization?
                           org_module.foobara_organization
                         end

          domain = Domain.new(domain_name: name.demodulize, organization:)

          organization&.register_domain(domain)

          domain
        end
      end

      def foobara_domain?
        true
      end

      delegate :depends_on, to: :foobara_domain
    end
  end
end
