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
      to_include = TypeDeclarations.foobara_manifest_context_to_include

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

      parent = scoped_namespace

      if parent
        parent_category = Namespace.global.foobara_category_symbol_for(parent)

        if parent_category
          if to_include
            to_include << parent
          end
          h[:parent] = [parent_category, parent.foobara_manifest_reference]
        end
      end

      h
    end
  end
end
