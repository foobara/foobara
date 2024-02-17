require_relative "module_extension"

module Foobara
  module GlobalOrganization
    foobara_namespace!(scoped_path: [])
    self.foobara_parent_namespace = Foobara
    Foobara.foobara_register(self)

    foobara_organization!
    self.foobara_manifest_reference = self.foobara_organization_name = "global_organization"
  end
end
