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

        def foobara_unregister(scoped)
          scoped = to_scoped(scoped)

          if scoped.is_a?(Foobara::Types::Type)
            parent_mod = nil

            if const_defined?(:Types, false)
              parent_path = ["Foobara::GlobalDomain"]
              unless scoped.type_symbol.to_s.start_with?("Types::")
                parent_path << "Types"
              end
              parent_path += scoped.type_symbol.to_s.split("::")[..-2]

              parent_name = parent_path.join("::")
              child_name = [*parent_path, scoped.type_symbol.to_s.split("::").last].join("::")
              removed = false

              if Object.const_defined?(parent_name)
                parent_mod = Object.const_get(parent_name)

                if scoped.scoped_short_name =~ /^[a-z]/
                  lower_case_constants = parent_mod.instance_variable_get(:@foobara_lowercase_constants)

                  if lower_case_constants&.include?(scoped.scoped_short_name)
                    parent_mod.singleton_class.undef_method scoped.scoped_short_name
                    lower_case_constants.delete(scoped.scoped_short_name)
                  end

                  removed = true
                elsif parent_mod.const_defined?(scoped.scoped_short_name, false)
                  parent_mod.send(:remove_const, scoped.scoped_short_name)
                  removed = true
                end
              end

              if removed
                child_name = parent_name

                while child_name
                  child = Object.const_get(child_name)

                  break if child.foobara_domain?
                  break if child.foobara_organization?

                  # TODO: unclear why we need this check, hmmm, figure it out and document it (or delete if not needed)
                  break if child.constants(false).any? do |constant|
                    # TODO: a clue: this stopped being entered by the test suite after deleting GlobalDomain::Types
                    # in .reset_alls hmmmmmm...
                    # :nocov:
                    value = child.const_get(constant)
                    value.is_a?(Types::Type) || (value.is_a?(::Class) && value.respond_to?(:foobara_type?))
                    # :nocov:
                  end

                  lower_case_constants = child.instance_variable_get(:@foobara_lowercase_constants)
                  break if lower_case_constants && !lower_case_constants.empty?

                  parent_name = Util.parent_module_name_for(child_name)
                  break unless Object.const_defined?(parent_name)

                  parent = Object.const_get(parent_name)

                  child_sym = Util.non_full_name(child).to_sym
                  parent.send(:remove_const, child_sym)

                  child_name = parent_name
                end
              end
            end
          end

          super
        end

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

          _set_type_constant(type)

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

        private

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
            const_name = [types_mod.name, *path[0..-2]].join("::")
            types_mod = Util.make_module_p(const_name, tag: true)
          end

          # TODO: dry this up
          if type.scoped_short_name =~ /\A[a-z]/
            unless types_mod.respond_to?(type.scoped_short_name)
              types_mod.singleton_class.define_method type.scoped_short_name do
                type
              end

              unless types_mod.instance_variable_defined?(:@foobara_lowercase_constants)
                types_mod.instance_variable_set(:@foobara_lowercase_constants, [])
              end

              types_mod.instance_variable_get(:@foobara_lowercase_constants) << type.scoped_short_name
            end
          elsif types_mod.const_defined?(type.scoped_short_name, false)
            existing_value = types_mod.const_get(type.scoped_short_name)
            existing_value_type = if existing_value.is_a?(::Class) && existing_value < Foobara::Model
                                    # TODO: test this code path
                                    # :nocov:
                                    existing_value.model_type
                                    # :nocov:
                                  else
                                    existing_value
                                  end

            if existing_value_type != type
              if existing_value.is_a?(::Module) && !existing_value.is_a?(::Class) &&
                 existing_value.instance_variable_get(:@foobara_created_via_make_class) &&
                 # not allowing lower-case "constants" to be namespaces
                 type.extends?("::model")

                types_mod.send(:remove_const, type.scoped_short_name)
                types_mod.const_set(type.scoped_short_name, type.target_class)

                Domain.copy_constants(existing_value, type.target_class)
              else
                # :nocov:
                raise CannotSetTypeConstantError,
                      "Already defined constant #{types_mod.name}::#{type.scoped_short_name}"
                # :nocov:
              end
            end
          else
            symbol = type.scoped_short_name

            if type.extends?("::model")
              type = type.target_class
            end

            types_mod.const_set(symbol, type)
          end
        end
      end
    end
  end
end
