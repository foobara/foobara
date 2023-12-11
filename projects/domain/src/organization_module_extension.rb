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

        # TODO: eliminate Organization
        def foobara_organization
          @foobara_organization ||= Organization.new(
            organization_name: Util.non_full_name(self),
            mod: self
          )
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

        def foobara_manifest(references = Set.new)
          domain_full_names = []

          foobara_domains.each do |domain|
            references << domain
            domain_full_names << domain.scoped_full_name
          end

          {
            organization_name: foobara_organization_name,
            domains: domain_full_names
          }
        end
      end
    end
  end
end
