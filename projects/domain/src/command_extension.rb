module Foobara
  module Domain
    # TODO: should we just couple domain project and commands project to simplify this connection?
    module CommandExtension
      include Concern

      class CannotAccessDomain < StandardError; end

      def run_subcommand!(subcommand_class, inputs = {})
        domain = self.class.domain

        return super unless domain

        sub_domain = subcommand_class.domain

        return super unless sub_domain

        unless domain.foobara_depends_on?(sub_domain)
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

          nil
        end

        def namespace
          domain&.foobara_type_namespace || TypeDeclarations::Namespace.global
        end

        def full_command_name
          @full_command_name ||= if domain
                                   "#{domain.foobara_full_domain_name}::#{command_name}"
                                 else
                                   command_name
                                 end
        end

        def full_command_symbol
          @full_command_symbol = if domain.global?
                                   command_symbol
                                 else
                                   "#{domain.foobara_full_domain_symbol}::#{command_symbol}".to_sym
                                 end
        end

        def manifest
          super.merge(
            command_name:,
            domain_name:,
            organization_name:
          )
        end

        def domain_name
          parent = foobara_parent_namespace

          if parent.foobara_domain?
            parent.scoped_name
          else
            "global_domain"
          end
        end

        def organization_name
          parent = foobara_parent_namespace

          if parent.foobara_domain?
            parent.foobara_parent_namespace.scoped_name
          end || "global_organization"
        end

        foobara_delegate :organization_symbol,
                         :domain_symbol,
                         to: :domain, allow_nil: true
      end
    end
  end
end
