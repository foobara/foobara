module Foobara
  module IsManifestable
    def foobara_manifest(to_include: Set.new)
      h = {
        scoped_path:,
        scoped_name:,
        scoped_short_name:,
        scoped_prefix:,
        scoped_full_path:,
        scoped_full_name:,
        scoped_category:,
        reference: foobara_manifest_reference
      }

      scoped = self
      parent = nil

      while scoped
        if scoped.is_a?(::Module)
          if scoped.foobara_organization?
            h[:organization] = scoped.foobara_manifest_reference
          elsif scoped.foobara_domain?
            h[:domain] = scoped.foobara_manifest_reference
          end
        end

        scoped = scoped.scoped_namespace
        parent ||= scoped
      end

      if parent
        parent_category = Foobara.foobara_category_symbol_for(parent)

        if parent_category
          to_include << parent
          h[:parent] = [parent_category, parent.foobara_manifest_reference]
        end
      end

      h
    end
  end
end
