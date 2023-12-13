module Foobara
  module Domain
    class NoSuchDomain < StandardError; end

    class << self
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
        when Types::Type
          namespace = TypeDeclarations::Namespace.namespace_for_type(object)
          domain_for_namespace(namespace)
        when Module
          if object.foobara_domain?
            object
          else
            # :nocov:
            raise NoSuchDomain, "Couldn't determine domain for #{object}"
            # :nocov:
          end
        else
          # :nocov:
          raise NoSuchDomain, "Couldn't determine domain for #{object}"
          # :nocov:
        end
      end

      def domain_for_namespace(namespace)
        Foobara.foobara_all_domain.find { |domain| domain.foobara_type_namespace == namespace }
      end

      def global
        GlobalDomain
      end
    end

    module DomainModuleExtension
      include Concern

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
          end
        end

        def foobara_domain?
          true
        end

        # TODO: kill this off
        def foobara_type_namespace
          @foobara_type_namespace ||= if self == GlobalDomain
                                        TypeDeclarations::Namespace.global
                                      else
                                        TypeDeclarations::Namespace.new(foobara_full_domain_name)
                                      end
        end

        # TODO: kill this
        def foobara_type_registered?(type_or_symbol)
          foobara_type_namespace.type_registered?(type_or_symbol)
        end

        def foobara_command_classes
          foobara_all_command(lookup_in_children: false)
        end

        def foobara_register_model(model_class)
          type = model_class.model_type
          foobara_type_namespace.register_type(model_class.model_symbol, type)
          foobara_register(type) # TODO: will this register it twice?
          type.foobara_parent_namespace = self
        end

        # TODO: kill this off
        def foobara_register_entity(name, attributes_type_declaration, model_base_class = nil)
          # TODO: introduce a Namespace#scope method to simplify this a bit
          TypeDeclarations::Namespace.using foobara_type_namespace do
            handler = foobara_type_namespace.handler_for_class(
              Foobara::TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
            )

            attributes_type = handler.type_for_declaration(attributes_type_declaration)

            # TODO: reuse the model_base_class primary key if it has one...
            primary_key = attributes_type.element_types.keys.first

            foobara_type_namespace.type_for_declaration(
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

            foobara_type_namespace.accesses << domain.foobara_type_namespace

            foobara_depends_on << domain_name
          end
        end

        def foobara_manifest(skip: nil)
          if skip
            allowed_keys = %i[
              organization_name
              domain_name
              depends_on
              commands
              types
            ]

            invalid_keys = skip - allowed_keys

            unless invalid_keys.empty?
              # :nocov:
              raise ArgumentError, "Invalid keys: #{invalid_keys} expected: #{allowed_keys}"
              # :nocov:
            end
          end

          organization_name = unless skip&.include?(:organization_name)
                                foobara_organization_name
                              end

          domain_name = unless skip&.include?(:domain_name)
                          foobara_domain_name
                        end

          depends_on = unless skip&.include?(:depends_on)
                         foobara_depends_on.map(&:to_s)
                       end

          commands = unless skip&.include?(:commands)
                       foobara_command_classes.map(&:manifest_hash).inject(:merge) || {}
                     end

          types = unless skip&.include?(:types)
                    foobara_type_namespace.manifest
                  end

          {
            organization_name:,
            domain_name:,
            depends_on:,
            commands:,
            types:
          }
        end

        def foobara_manifest_hash
          {
            foobara_domain_name.to_sym => foobara_manifest
          }
        end
      end
    end
  end
end
