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
      end
    end
  end
end
