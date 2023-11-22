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
          @full_command_name ||= if domain.global?
                                   command_name
                                 elsif organization.global?
                                   "#{domain_name}::#{command_name}"
                                 else
                                   "#{organization_name}::#{domain_name}::#{command_name}"
                                 end
        end

        def full_command_symbol
          @full_command_symbol = if domain.global?
                                   command_symbol
                                 elsif organization.global?
                                   "#{domain_symbol}::#{command_symbol}".to_sym
                                 else
                                   "#{organization_symbol}::#{domain_symbol}::#{command_symbol}".to_sym
                                 end
        end

        def organization
          domain.organization
        end

        def manifest(verbose: false)
          if verbose
            super.merge(
              command_name:,
              domain_name:,
              organization_name:
            )
          else
            # TODO: this seems awkward
            super(verbose: true)
          end
        end

        foobara_delegate :domain_name,
                         :organization_name,
                         :organization_symbol,
                         :domain_symbol,
                         to: :domain, allow_nil: true
      end
    end
  end
end
