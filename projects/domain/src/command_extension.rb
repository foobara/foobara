module Foobara
  module Domain
    # TODO: should we just couple domain project and commands project to simplify this connection?
    module CommandExtension
      include Concern

      module ClassMethods
        def foobara_manifest(to_include:)
          super.merge(
            command: foobara_manifest_reference,
            domain_name: domain.foobara_manifest_reference,
            organization_name: organization.foobara_manifest_reference
          )
        end
      end
    end
  end
end
