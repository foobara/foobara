module Foobara
  module Domain
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
          namespace = foobara_parent_namespace

          while namespace
            if namespace.is_a?(Module) && namespace.foobara_domain?
              return namespace
            end

            namespace = namespace.foobara_parent_namespace
          end

          Domain.global
        end

        def namespace
          domain.foobara_type_namespace
        rescue => e
          binding.pry
          raise
        end

        def full_command_name
          @full_command_name ||= if domain.global?
                                   command_name
                                 else
                                   "#{domain.foobara_full_domain_name}::#{command_name}"
                                 end
        end

        def full_command_symbol
          @full_command_symbol = if domain.global?
                                   command_symbol
                                 else
                                   "#{domain.foobara_full_domain_symbol}::#{command_symbol}".to_sym
                                 end
        end

        def organization
          domain.foobara_organization || Domain.global
        end

        def manifest
          super.merge(
            command_name:,
            domain_name:,
            organization_name:
          )
        end

        def domain_name
          domain_name = foobara_parent_namespace.scoped_name || "global_domain"

          # TODO: remove this old method of doing things!!!
          old_domain_name = domain.domain_name

          unless old_domain_name == domain_name
            # :nocov:
            raise "Domain name in new system doesn't match old system: #{old_domain_name} != #{domain_name}"
            # :nocov:
          end

          domain_name
        end

        def organization_name
          parent = foobara_parent_namespace

          name = if parent.foobara_domain?
                   parent.foobara_parent_namespace.scoped_name
                 end || "global_organization"

          # TODO: remove this old method of doing things!!
          old_name = domain.organization_name

          unless old_name == name
            # :nocov:
            raise "Organization name in new system doesn't match old system: #{old_name} != #{name}"
            # :nocov:
          end

          name
        rescue => e
          binding.pry
          raise
        end

        foobara_delegate :organization_symbol,
                         :domain_symbol,
                         to: :domain, allow_nil: true
      end
    end
  end
end
