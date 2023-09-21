module Foobara
  class Domain
    # TODO: should we just couple domain project and commands project to simplify this connection?
    module CommandExtension
      include Concern

      class CannotAccessDomain < StandardError; end

      def run_subcommand!(subcommand_class, inputs = {})
        domain = self.class.domain

        return super if domain.global?

        sub_domain = subcommand_class.domain

        return super if sub_domain.global?

        unless domain.depends_on?(sub_domain)
          raise CannotAccessDomain,
                "Cannot access #{sub_domain} or its commands because #{domain} does not depend on it"
        end

        super
      end

      module ClassMethods
        def domain
          mod = Util.module_for(self)

          if mod&.foobara_domain?
            mod.foobara_domain
          end || Domain.global
        end

        def namespace
          domain.type_namespace
        end

        def full_command_name
          [
            organization.organization_name,
            domain.domain_name,
            command_name
          ].compact.join("::").presence
        end

        def organization
          domain.organization
        end

        def manifest
          super.merge(full_command_name:)
        end

        delegate :domain_name, :organization_name, to: :domain, allow_nil: true
      end
    end
  end
end
