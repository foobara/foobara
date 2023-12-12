module Foobara
  module Domain
    module OrganizationModuleExtension
      # Does this really need to be a Concern?
      include Concern

      module ClassMethods
        def foobara_organization_name
          scoped_name
        end

        def foobara_organization_symbol
          Util.underscore_sym(foobara_organization_name)
        end

        def foobara_organization?
          true
        end

        def foobara_owns_domain?(domain)
          foobara_each_domain(lookup_in_children: false) do |d|
            if d == domain || (d == domain.mod if domain.respond_to?(:mod))
              return true
            end
          end

          false
        end

        def foobara_domains
          foobara_all_domain(lookup_in_children: false).map(&:foobara_domain)
        end

        def foobara_manifest
          {
            organization_name: foobara_organization_name,
            domains: foobara_domains.map(&:manifest_hash).inject(:merge) || {}
          }
        end
      end
    end
  end
end
