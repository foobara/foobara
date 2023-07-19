module Foobara
  class Domain
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
          return @domain if defined?(@domain)

          namespace = Foobara::Util.module_for(self)

          if namespace&.ancestors&.include?(Foobara::Domain)
            @domain = namespace
          end
        end
      end
    end
  end
end
