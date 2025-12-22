module Foobara
  module Domain
    class NoSuchDomain < StandardError; end
    class AlreadyRegisteredError < StandardError; end
    class CannotSetTypeConstantError < StandardError; end

    class << self
      def global
        GlobalDomain
      end
    end

    module DomainModuleExtension
      include Concern
      include Manifestable

      module ClassMethods
        attr_writer :foobara_domain_name, :foobara_full_domain_name

        def foobara_domain_map(*args, to: nil, strict: false, criteria: nil, should_raise: false, **opts)
          case args.size
          when 1
            value = args.first
          when 0
            if opts.empty?
              # :nocov:
              raise ArgumentError, "Expected at least one argument"
              # :nocov:
            else
              value = opts
              opts = {}
            end
          else
            # :nocov:
            raise ArgumentError, "Expected 1 argument but got #{args.size}"
            # :nocov:
          end

          invalid_keys = opts.keys - [:from]

          if invalid_keys.any?
            # :nocov:
            raise ArgumentError, "Invalid options: #{invalid_keys.join(", ")}"
            # :nocov:
          end

          from = if opts.key?(:from)
                   opts[:from]
                 else
                   value
                 end

          mapper = lookup_matching_domain_mapper(from:, to:, criteria:, strict:)

          if mapper
            mapper.map!(value)
          elsif should_raise
            raise Foobara::DomainMapperLookups::NoDomainMapperFoundError.new(from, to, value:)
          end
        end

        def foobara_domain_map!(*, **, &)
          foobara_domain_map(*, should_raise: true, **, &)
        end

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

        def foobara_type_from_declaration(*args, **opts, &block)
          if opts.empty? && block.nil? && args.size == 1 && args.first.is_a?(Types::Type)
            return args.first
          end

          Foobara::Namespace.use self do
            foobara_type_builder.type_for_declaration(*args, **opts, &block)
          end
        end

        def foobara_type_from_strict_stringified_declaration(...)
          Foobara::Namespace.use self do
            foobara_type_builder.type_for_strict_stringified_declaration(...)
          end
        end

        def foobara_type_from_strict_declaration(...)
          Foobara::Namespace.use self do
            foobara_type_builder.type_for_strict_declaration(...)
          end
        end

        def foobara_register_type(type_symbol, *type_declaration_bits, &block)
          type = if block.nil? && type_declaration_bits.size == 1 && type_declaration_bits.first.is_a?(Types::Type)
                   type_declaration_bits.first
                 else
                   foobara_type_from_declaration(*type_declaration_bits, &block)
                 end

          new_scoped_path, new_type_symbol = if type_symbol.is_a?(::Array)
                                               [type_symbol, type_symbol.join("::").to_sym]
                                             else
                                               type_symbol = type_symbol.to_s if type_symbol.is_a?(::Symbol)

                                               [type_symbol.split("::"), type_symbol.to_sym]
                                             end

          if type.scoped_path_set? && type.registered? && foobara_registered?(type, mode: Namespace::LookupMode::DIRECT)
            old_symbol = type.type_symbol
            old_type = foobara_lookup_type(old_symbol, mode: Namespace::LookupMode::DIRECT)

            if old_symbol != new_type_symbol
              foobara_unregister(type)

              type.scoped_path = new_scoped_path
              type.type_symbol = new_type_symbol

              foobara_register(type)
              # :nocov:
            elsif old_type != type
              # TODO: delete this check if it's not really helping

              raise "Didn't expect to find an old type"
              # :nocov:
            end
          else
            type.scoped_path = new_scoped_path
            type.type_symbol = new_type_symbol

            old_type = foobara_lookup_type(new_type_symbol, mode: Namespace::LookupMode::DIRECT)

            if old_type && old_type != type
              # TODO: delete this check if it's not really helping
              # :nocov:
              raise "Didn't expect to find an old type"
              # :nocov:
            end

            if foobara_registered?(type, mode: Namespace::LookupMode::DIRECT)
              # TODO: delete this check if it's not really helping
              # :nocov:
              raise "Already registered: #{type.inspect}"
              # :nocov:
            end

            foobara_register(type)
          end

          type
        end

        def foobara_depends_on?(other_domain)
          other_domain = Domain.to_domain(other_domain)
          other_domain == GlobalDomain || foobara_depends_on.include?(other_domain.foobara_full_domain_name)
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

            lru_cache.reset!
            foobara_depends_on << domain_name
          end
        end

        def foobara_manifest
          to_include = TypeDeclarations.foobara_manifest_context_to_include

          depends_on = foobara_depends_on.map do |name|
            domain = Domain.to_domain(name)
            if to_include
              to_include << domain
            end
            domain.foobara_manifest_reference
          end.sort

          types = foobara_all_type(mode: Namespace::LookupMode::DIRECT).map do |type|
            if to_include
              to_include << type
            end
            type.foobara_manifest_reference
          end.sort

          manifest = super.merge(types:)

          unless depends_on.empty?
            manifest[:depends_on] = depends_on
          end

          manifest
        end
      end
    end
  end
end
