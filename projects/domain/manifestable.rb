module Foobara
  module Manifestable
    def foobara_manifest(to_include: Set.new)
      h = {
        scoped_path:,
        scoped_full_path:,
        scoped_full_name:
      }

      scoped = self
      parent = nil

      while scoped
        if scoped.is_a?(::Module)
          if scoped.foobara_organization?
            h[:organization] = scoped.foobara_manifest_reference
          elsif scoped.foobara_domain?
            h[:domain] = domain.foobara_manifest_reference
          end
        end

        scoped = scoped.foobara_parent_namespace
        parent ||= scoped
      end

      if parent
        h[:parent] = [foobara_category_for(parent), parent.foobara_manifest_reference]
      end

      h
    end
  end
end
