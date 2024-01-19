module Foobara
  module Domain
    class NoSuchDomain < StandardError; end
    class AlreadyRegisteredError < StandardError; end

    class << self
      # TODO: move this to domain.rb
      def to_domain(object)
        case object
        when nil
          global
        when ::String, ::Symbol
          domain = Foobara.foobara_lookup_domain(object)

          unless domain
            # :nocov:
            raise NoSuchDomain, "Couldn't determine domain for #{object}"
            # :nocov:
          end

          domain
        when Foobara::Scoped
          if object.is_a?(Module) && object.foobara_domain?
            object
          else
            parent = object.scoped_namespace

            if parent
              to_domain(parent)
            else
              GlobalDomain
            end
          end
        else
          # :nocov:
          raise NoSuchDomain, "Couldn't determine domain for #{object}"
          # :nocov:
        end
      end

      def global
        GlobalDomain
      end
    end

    module DomainModuleExtension
      class << self
        def all
          @all ||= []
        end
      end
      include Concern
      include Manifestable

      on_include do
        DomainModuleExtension.all << self
      end

      module ClassMethods
        attr_writer :foobara_domain_name, :foobara_full_domain_name

        def foobara_domain_name
          # TODO: eliminate this global concept concept
          @foobara_domain_name || scoped_name
        end

        def foobara_full_domain_name
          @foobara_full_domain_name || scoped_full_name
        end

        def foobara_full_domain_symbol
          Util.underscore_sym(foobara_full_domain_name)
        end

        def foobara_organization_name
          foobara_organization&.foobara_organization_name
        end

        def foobara_organization
          parent = foobara_parent_namespace

          while parent
            return parent if parent&.foobara_organization?

            # TODO: we really should test this path
            # :nocov:
            parent = parent.foobara_parent_namespace
            # :nocov:
          end || GlobalOrganization
        end

        def foobara_domain?
          true
        end

        # TODO: kill this off
        def foobara_type_builder
          @foobara_type_builder ||= begin
            accesses = self == GlobalDomain ? [] : GlobalDomain.foobara_type_builder
            TypeDeclarations::TypeBuilder.new(foobara_full_domain_name, accesses:)
          end
        end

        def foobara_type_from_declaration(type_declaration)
          Foobara::Namespace.use self, foobara_type_builder do
            foobara_type_builder.type_for_declaration(type_declaration)
          end
        end

        def foobara_command_classes
          foobara_all_command(lookup_in_children: false)
        end

        def foobara_register_model(model_class, reregister: false)
          type = model_class.model_type

          if type.scoped_path_set? && foobara_registered?(type.scoped_full_name, absolute: true,
                                                                                 lookup_in_children: false)
            if reregister
              foobara_unregister(type)
            else
              # :nocov:
              raise AlreadyRegisteredError, "Already registered: #{type}"
              # :nocov:
            end
          end

          foobara_register(type)
          type.foobara_parent_namespace = self
        end

        def foobara_reregister_model(model_class)
          foobara_register_model(model_class, reregister: true)
        end

        # TODO: kill this off
        def foobara_register_entity(name, attributes_type_declaration, model_base_class = nil)
          # TODO: introduce a Namespace#scope method to simplify this a bit
          Foobara::Namespace.use self, foobara_type_builder do
            handler = foobara_type_builder.handler_for_class(
              Foobara::TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
            )

            attributes_type = handler.type_for_declaration(attributes_type_declaration)

            # TODO: reuse the model_base_class primary key if it has one...
            primary_key = attributes_type.element_types.keys.first

            foobara_type_builder.type_for_declaration(
              type: :entity,
              name:,
              model_base_class:,
              attributes_declaration: attributes_type_declaration,
              model_module: self,
              primary_key:
            )
          end
        end

        def foobara_register_entities(entity_names_to_attributes)
          entity_names_to_attributes.each_pair do |entity_name, attributes_type_declaration|
            foobara_register_entity(entity_name, attributes_type_declaration)
          end

          nil
        end

        def foobara_depends_on?(other_domain)
          other_domain = Domain.to_domain(other_domain)

          # TODO: Feels awkward to have to check if we're the global domain or not here.
          # Also awkward to check if the other domain is global.
          # Unclear what the solution is. To fix other domain check could just automatically call
          # depends_on with the global domain in .foobara_domain! but not as clear how to fix the check
          # against self.
          self == GlobalDomain || other_domain == self || other_domain == GlobalDomain ||
            foobara_depends_on.include?(other_domain.foobara_full_domain_name)
        end

        def foobara_depends_on(*domains)
          if domains.empty?
            return @foobara_depends_on ||= Set.new
          end

          if domains.length == 1
            domains = Util.array(domains.first)
          end

          domains.each do |domain|
            # It very likely could be a module extended with domain methods...
            domain = Domain.to_domain(domain)
            domain_name = domain.foobara_full_domain_name

            if foobara_depends_on.include?(domain_name)
              # :nocov:
              raise AlreadyRegisteredDomainDependency, "Already registered #{domain_name} as a dependency of #{self}"
              # :nocov:
            end

            # TODO: need to address this?
            foobara_type_builder.accesses << domain.foobara_type_builder

            foobara_depends_on << domain_name
          end
        end

        # TODO: can we kill this skip concept?
        def foobara_manifest(to_include:)
          organization_name = foobara_organization_name

          domain_name = foobara_domain_name

          depends_on = foobara_depends_on.map do |name|
            domain = Domain.to_domain(name)
            to_include << domain
            domain.foobara_manifest_reference
          end

          commands = foobara_all_command(lookup_in_children: false).map do |command_class|
            to_include << command_class
            command_class.foobara_manifest_reference
          end

          types = foobara_all_type(lookup_in_children: false).map do |type|
            to_include << type
            type.foobara_manifest_reference
          end

          super(to_include:).merge(
            organization_name:,
            domain_name:,
            depends_on:,
            commands:,
            types:
          )
        end
      end
    end
  end
end
