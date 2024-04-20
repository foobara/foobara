module Foobara
  module Domain
    class NoSuchDomain < StandardError; end
    class AlreadyRegisteredError < StandardError; end

    class << self
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
          # TODO: does this work properly with prefixes?
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

        def foobara_full_organization_name
          foobara_organization&.foobara_full_organization_name
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

        def foobara_type_from_declaration(...)
          Foobara::Namespace.use self do
            foobara_type_builder.type_for_declaration(...)
          end
        end

        def foobara_command_classes
          foobara_all_command(mode: Namespace::LookupMode::DIRECT)
        end

        def foobara_register_type(type_symbol, ...)
          type = foobara_type_from_declaration(...)

          if type_symbol.is_a?(::Array)
            type.scoped_path = type_symbol
            type.type_symbol = type_symbol.join("::")
          else
            type.scoped_path = [type_symbol]
            type.type_symbol = type_symbol
          end

          type.foobara_parent_namespace ||= self
          foobara_register(type)

          _set_type_constant(type)

          type
        end

        def foobara_register_model(model_class, reregister: false)
          type = model_class.model_type

          if type.scoped_path_set? && foobara_registered?(type.scoped_full_name, mode: Namespace::LookupMode::DIRECT)
            if reregister
              foobara_unregister(type)
            else
              # :nocov:
              raise AlreadyRegisteredError, "Already registered: #{type.inspect}"
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
        def foobara_register_entity(name, *args, &block)
          # TODO: introduce a Namespace#scope method to simplify this a bit
          Foobara::Namespace.use self do
            if block
              args = [TypeDeclarations::Dsl::Attributes.to_declaration(&block), *args]
            end

            attributes_type_declaration, *args = args

            model_base_class, description = case args.size
                                            when 0
                                              []
                                            when 1, 2
                                              arg, other = args

                                              if args.first.is_a?(::String)
                                                [other, arg]
                                              else
                                                args
                                              end
                                            else
                                              # :nocov:
                                              raise ArgumentError, "Too many arguments"
                                              # :nocov:
                                            end

            if model_base_class
              attributes_type_declaration = TypeDeclarations::Attributes.merge(
                model_base_class.attributes_type.declaration_data,
                attributes_type_declaration
              )
            end

            handler = foobara_type_builder.handler_for_class(
              Foobara::TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
            )

            attributes_type = handler.type_for_declaration(attributes_type_declaration)

            # TODO: reuse the model_base_class primary key if it has one...
            primary_key = attributes_type.element_types.keys.first

            foobara_type_builder.type_for_declaration(
              Util.remove_blank(
                type: "::entity",
                name:,
                model_base_class:,
                attributes_declaration: attributes_type_declaration,
                model_module: self,
                primary_key:,
                description:
              )
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

            foobara_depends_on_namespaces << domain
            foobara_type_builder.accesses << domain.foobara_type_builder

            foobara_depends_on << domain_name
          end
        end

        # TODO: can we kill this skip concept?
        def foobara_manifest(to_include:)
          depends_on = foobara_depends_on.map do |name|
            domain = Domain.to_domain(name)
            to_include << domain
            domain.foobara_manifest_reference
          end.sort

          commands = foobara_all_command(mode: Namespace::LookupMode::DIRECT).map do |command_class|
            to_include << command_class
            command_class.foobara_manifest_reference
          end.sort

          types = foobara_all_type(mode: Namespace::LookupMode::DIRECT).map do |type|
            to_include << type
            type.foobara_manifest_reference
          end.sort

          manifest = super.merge(commands:, types:)

          unless depends_on.empty?
            manifest[:depends_on] = depends_on
          end

          manifest
        end

        def _set_type_constant(type)
          domain = if scoped_full_path.empty?
                     GlobalDomain
                   else
                     self
                   end

          path = type.scoped_path
          if path.first == "Types"
            path = path[1..]
          end

          types_mod = if domain.const_defined?(:Types)
                        domain.const_get(:Types)
                      else
                        domain.const_set(:Types, Module.new)
                      end

          if type.scoped_prefix
            types_mod = Util.make_module_p("#{types_mod.name}::#{path[0..-2].join("::")}")
          end

          if type.scoped_short_name =~ /\A[a-z]/
            unless types_mod.respond_to?(type.scoped_short_name)
              types_mod.singleton_class.define_method type.scoped_short_name do
                type
              end
            end
          else
            types_mod.const_set(type.scoped_short_name, type)
          end
        end
      end
    end
  end
end
