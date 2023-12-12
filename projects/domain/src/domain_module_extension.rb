module Foobara
  module Domain
    class << self
      def to_domain(object)
        case object
        when nil
          global
        when ::String, ::Symbol
          domain = foobara_lookup_domain(object)

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

      def unprocessed_command_classes
        @unprocessed_command_classes ||= []
      end

      def process_command_classes
        until unprocessed_command_classes.empty?
          command_class = unprocessed_command_classes.pop
          domain = command_class.domain

          domain&.register_command(command_class)
        end
      end
    end

    module DomainModuleExtension
      include Concern

      module ClassMethods
        # TODO: eliminate this concept
        attr_accessor :is_global

        # TODO: eliminate this concept
        def global?
          is_global
        end

        def foobara_domain_name
          # TODO: eliminate this global concept concept
          global? ? "global_domain" : scoped_name
        end

        def foobara_full_domain_name
          global? ? "global_organization::global_domain" : scoped_full_name
        end

        def foobara_domain_symbol
          Util.underscore_sym(foobara_domain_name)
        end

        def foobara_full_domain_symbol
          Util.underscore_sym(foobara_full_domain_name)
        end

        def foobara_organization_name
          global? ? "global_organization" : foobara_organization&.foobara_organization_name
        end

        def foobara_organization
          parent = foobara_parent_namespace

          if parent&.foobara_organization?
            parent
          else
            GlobalDomain
          end
        end

        def foobara_domain?
          true
        end

        # TODO: kill this off
        def foobara_type_namespace
          @foobara_type_namespace ||= if global?
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
        rescue => e
          binding.pry
          raise
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

            type_for_declaration(
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
          return true if global? # This doesn't make sense shouldn't this be false??

          other_domain = Domain.to_domain(other_domain)

          other_domain.global? || other_domain == self ||
            foobara_depends_on.include?(other_domain.foobara_full_domain_name)
        end

        def foobara_depends_on(*domains)
          return @foobara_depends_on ||= Set.new if domains.empty?

          if domains.length == 1
            domains = Util.array(domains.first)
          end

          domains.each do |domain|
            # It very likely could be a module extended with domain methods...
            domain = Domain.to_domain(domain)
            domain_name = domain.foobara_full_domain_name

            if foobar_depends_on.include?(domain_name)
              # :nocov:
              raise AlreadyRegisteredDomainDependency, "Already registered #{domain_name} as a dependency of #{self}"
              # :nocov:
            end

            type_namespace.accesses << domain.foobara_type_namespace

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
