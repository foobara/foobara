module Foobara
  class Domain
    module OrganizationModuleExtension
      # Does this really need to be a Concern?
      include Concern

      module ClassMethods
        # TODO: eliminate this concept
        attr_accessor :is_global

        # TODO: eliminate this concept
        def global?
          is_global
        end

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
          foobara_each_domain do |d|
            if d == domain || (d == domain.mod if domain.respond_to?(:mod))
              return true
            end
          end

          false
        end

        def foobara_manifest
          domains = foobara_all_domain

          binding.pry
          {
            organization_name: foobara_organization_name,
            domains: domains.map(&:foobara_domain).map(&:manifest_hash).inject(:merge) || {}
          }
        end
      end
    end
  end
end
