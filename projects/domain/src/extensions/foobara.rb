module Foobara
  class << self
    # TODO: come up with a way to change a type's manifest... Or maybe treat Model very differently?
    # ok... new manifest will be of this form...
    # { <orgs|commands|types, etc, letś call this a type category...> => full_scoped_name => manifest }
    #
    # The manifest itself will only contain full scoped names. This is kind of analogous to a store serializer
    # in the http connector.
    def manifest
      to_include = foobara_all_organization.to_set
      included = {}

      h = {}

      until to_include.empty?
        object = to_include.first
        to_include.delete(object)

        unless object.scoped_path_set?
          # :nocov:
          raise "no scoped path set for #{object}"
          # :nocov:
        end

        manifest_reference = object.foobara_manifest_reference.to_sym
        category_symbol = Foobara.foobara_category_symbol_for(object)

        unless category_symbol
          # :nocov:
          raise "no category symbol for #{object}"
          # :nocov:
        end

        if included.key?(manifest_reference)
          if included[manifest_reference] == category_symbol
            next
          else
            # :nocov:
            raise "Collision for #{manifest_reference}: #{included[manifest_reference]} and #{category_symbol}"
            # :nocov:
          end
        end

        cat = h[category_symbol] ||= {}
        cat[manifest_reference] = object.foobara_manifest(to_include:)

        included[manifest_reference] = category_symbol
      end

      h.sort.to_h
    end

    def all_domains
      foobara_all_domain
    end

    def all_commands
      foobara_all_command
    end

    def all_types
      foobara_all_type
    end
  end
end
