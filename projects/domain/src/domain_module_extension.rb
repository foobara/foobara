module Foobara
  class Domain
    module DomainModuleExtension
      include Concern

      module ClassMethods
        def foobara_domain
          @foobara_domain ||= begin
            org_module = Util.module_for(self)

            organization = if org_module&.foobara_organization?
                             org_module.foobara_organization
                           else
                             Organization.global
                           end

            Domain.new(domain_name: Util.non_full_name(self), organization:, mod: self)
          end
        end

        def foobara_domain?
          true
        end

        foobara_delegate :depends_on,
                         :type_for_declaration,
                         :register_entity,
                         :register_entities,
                         to: :foobara_domain
      end
    end
  end
end
