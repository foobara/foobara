module Foobara
  class << self
    # TODO: come up with a way to change a type's manifest... Or maybe treat Model very differently?
    # ok... new manifest will be of this form...
    # { <orgs|commands|types, etc, letś call this a type category...> => full_scoped_name => manifest }
    #
    # The manifest itself will only contain full scoped names. This is kind of analogous to a store serializer
    # in the http connector.
    def manifest(to_include: nil)
      to_include = if to_include
                     to_include.dup.to_set
                   else
                     foobara_all_organization.to_set
                   end

      included = Set.new

      h = {}

      until to_include.empty?
        object = to_include.first
        to_include.delete(object)

        if object.is_a?(::String) || object.is_a?(::Symbol)
          object = Foobara.foobara_lookup!(object, absolute: true)
        end

        manifest_reference = object.foobara_manifest_reference.to_sym

        next if included.include?(manifest_reference)

        category_symbol = Foobara.foobara_category_symbol_for(object)

        unless category_symbol
          raise "no category symbol for #{object}"
        end

        cat = h[category_symbol] ||= {}
        cat[manifest_reference] = object.foobara_manifest(to_include:)

        included << manifest_reference
      end

      h
    end

    def all_domains
      foobara_all_domain
    end

    def all_types
      all_namespaces.map(&:all_types).flatten
    end

    def all_namespaces
      [*all_domains.map(&:foobara_type_namespace), TypeDeclarations::Namespace.global]
    end
  end
end
