module Foobara
  module Domain
    # TODO: should we just couple domain project and commands project to simplify this connection?
    module CommandExtension
      include Concern

      module ClassMethods
        def domain
          namespace = foobara_parent_namespace

          while namespace
            if namespace.is_a?(Module) && namespace.foobara_domain?
              d = namespace
              break
            end

            namespace = namespace.foobara_parent_namespace
          end

          d
        end

        # TODO: prefix these...
        def organization
          domain.foobara_organization
        end

        def full_command_name
          scoped_full_name
        end

        def full_command_symbol
          @full_command_symbol ||= Util.underscore_sym(full_command_name)
        end

        def foobara_manifest(to_include:)
          super.merge(
            command: foobara_manifest_reference,
            domain_name: domain.foobara_manifest_reference,
            organization_name: organization.foobara_manifest_reference
          )
        end

        foobara_delegate :organization_symbol,
                         :domain_symbol,
                         to: :domain, allow_nil: true
      end
    end
  end
end
