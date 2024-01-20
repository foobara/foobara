require_relative "manifestable"

module Foobara
  module Domain
    module OrganizationModuleExtension
      # Does this really need to be a Concern?
      include Concern
      include Manifestable

      module ClassMethods
        attr_writer :foobara_organization_name

        def foobara_organization_name
          @foobara_organization_name || scoped_name
        end

        def foobara_organization?
          true
        end

        def foobara_owns_domain?(domain)
          foobara_each_domain(mode: Namespace::LookupMode::DIRECT) do |d|
            if d == domain || (d == domain.mod if domain.respond_to?(:mod))
              return true
            end
          end

          false
        end

        def foobara_domains
          foobara_all_domain(mode: Namespace::LookupMode::DIRECT)
        end

        def foobara_manifest(to_include:)
          domain_names = []

          foobara_domains.each do |domain|
            to_include << domain
            domain_names << domain.foobara_manifest_reference
          end

          super.merge(
            organization_name: foobara_organization_name,
            domains: domain_names
          )
        end
      end
    end
  end
end
