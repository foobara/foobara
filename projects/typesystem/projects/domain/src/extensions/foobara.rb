module Foobara
  class << self
    def manifest
      # simplecov:disable
      warn "Foobara.manifest is deprecated in favor of CommandConnector#foobara_manifest" \
           "\nIf this breaks a legit use case for Foobara.manifest please let us know and we will consider keeping it!"
      debug_manifest
      # simplecov:enable
    end

    private def debug_manifest
      to_include = Namespace.global.foobara_all_organization.to_set

      TypeDeclarations.with_manifest_context(to_include:) do
        included = {}

        h = {}

        until to_include.empty?
          object = to_include.first
          to_include.delete(object)

          unless object.scoped_path_set?
            # simplecov:disable
            raise "no scoped path set for #{object}"
            # simplecov:enable
          end

          manifest_reference = object.foobara_manifest_reference.to_sym
          category_symbol = Namespace.global.foobara_category_symbol_for(object)

          unless category_symbol
            # simplecov:disable
            raise "no category symbol for #{object}"
            # simplecov:enable
          end

          if included.key?(manifest_reference)
            if included[manifest_reference] == category_symbol
              next
            else
              # simplecov:disable
              raise "Collision for #{manifest_reference}: #{included[manifest_reference]} and #{category_symbol}"
              # simplecov:enable
            end
          end

          cat = h[category_symbol] ||= {}
          cat[manifest_reference] = object.foobara_manifest

          included[manifest_reference] = category_symbol
        end

        h.sort.to_h
      end
    end

    def all_organizations
      Namespace.global.foobara_all_organization
    end

    def all_domains
      Namespace.global.foobara_all_domain
    end

    def all_types
      Namespace.global.foobara_all_type
    end
  end
end
