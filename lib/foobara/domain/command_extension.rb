module Foobara
  class Domain
    # TODO: should we just couple domain project and commands project to simplify this connection?
    module CommandExtension
      extend ActiveSupport::Concern

      class CannotAccessDomain < StandardError; end

      def run_subcommand!(subcommand_class, inputs = {})
        domain = self.class.domain

        if domain
          sub_domain = subcommand_class.domain

          if sub_domain && (sub_domain != domain && !domain.depends_on?(sub_domain))
            raise CannotAccessDomain,
                  "Cannot access #{sub_domain} or its commands because #{domain} does not depend on it"
          end
        end

        super
      end

      class_methods do
        def domain
          mod = Util.module_for(self)

          if mod&.foobara_domain?
            mod.foobara_domain
          end
        end

        def namespace
          if domain.present?
            domain.type_namespace
          else
            super
          end
        end

        def full_command_name
          [
            organization&.organization_name,
            domain&.domain_name,
            command_name
          ].compact.join("::")
        end

        def organization
          domain&.organization
        end

        def to_h
          super.merge(
            domain_name:,
            organization_name:,
            full_command_name:
          )
        end

        delegate :domain_name, :organization_name, to: :domain, allow_nil: true
      end
    end
  end
end
