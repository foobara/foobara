require_relative "global_organization"

module Foobara
  module GlobalDomain
    foobara_namespace!(scoped_path: [])
    GlobalOrganization.foobara_register(self)

    foobara_domain!

    self.foobara_domain_name = "global_domain"
    self.foobara_full_domain_name = "#{GlobalOrganization.foobara_organization_name}::#{foobara_domain_name}"
    self.foobara_manifest_reference = foobara_full_domain_name
  end
end
