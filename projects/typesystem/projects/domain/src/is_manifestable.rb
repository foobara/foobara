module Foobara
  module IsManifestable
    def scoped_clear_caches
      [
        # TODO: what about this one??
        # "@created_in_namespace",
        "@foobara_domain"
      ].each do |variable|
        remove_instance_variable(variable) if instance_variable_defined?(variable)
      end

      super
    end

    def foobara_domain
      return @foobara_domain if defined?(@foobara_domain)

      scoped = self

      while scoped
        if scoped.is_a?(::Module)
          if scoped.foobara_domain?
            return @foobara_domain = scoped
          end
        end

        scoped = scoped.scoped_namespace
      end

      @foobara_domain = GlobalDomain
    end

    def foobara_organization
      if is_a?(::Module) && foobara_organization?
        self
      else
        foobara_domain.foobara_organization
      end
    end

    def foobara_manifest
      to_include = TypeDeclarations.foobara_manifest_context_to_include || Set.new
      include_processors = TypeDeclarations.include_processors?

      h = {
        scoped_path:,
        scoped_name:,
        scoped_short_name:,
        scoped_prefix:,
        scoped_full_path:,
        scoped_full_name:,
        scoped_category:,
        reference: foobara_manifest_reference,
        domain: foobara_domain&.foobara_manifest_reference,
        organization: foobara_organization&.foobara_manifest_reference
      }

      candidate = scoped_namespace
      parent = nil

      while candidate
        parent_category = Namespace.global.foobara_category_symbol_for(candidate)
        break unless parent_category

        if parent_category
          if include_processors || (parent_category != :processor && parent_category != :processor_class)
            parent = if candidate == Foobara::Value
                       GlobalDomain
                     else
                       candidate
                     end
            break
          end
        end

        candidate = candidate.scoped_namespace
      end

      if parent == GlobalDomain
        h[:scoped_path] = scoped_full_path
        h[:scoped_name] = scoped_full_name
        h[:scoped_prefix] = scoped_full_path[..-2]
        h[:domain] = parent.foobara_manifest_reference
        h[:organization] = parent.foobara_organization.foobara_manifest_reference
      end

      if parent
        to_include << parent
        h[:parent] = [parent_category, parent.foobara_manifest_reference]
      end

      h
    end
  end
end
