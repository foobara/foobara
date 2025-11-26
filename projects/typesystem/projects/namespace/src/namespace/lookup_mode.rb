module Foobara
  class Namespace
    # TODO: need to define these better/more intuitively
    # use-cases
    # 1. general: just general lookup. find it wherever the heck it might be
    #   children: y
    #   parent: y
    #   dependent: y
    # 2. direct: only this namespace. we want to know what this namespace directly owns
    #   children: n
    #   parent: n
    #   dependent: n
    # 3. strict
    #   children: n
    #   parent: y
    #   dependent: n
    # 4. absolute
    #   children: y
    #   parent: n
    #   dependent: y
    # 5. absolute_single_namespace
    #   children: y
    #   parent: n
    #   dependent: n
    # 6. children_only (internal use... absolute and absolute_single_namespace jump to top, children only does not)
    #   children: y
    #   parent: n
    #   dependent: n
    # TODO: don't we have an enumerated class/project for this?
    # Maybe use bitmasks for the above 3 places to look instead of a list of 7 lookup types? (There should be 8...)
    module LookupMode
      GENERAL = :general
      # Relaxed will allow you to find registered entries without prefixes as long as it's not ambiguous
      # So if there is a SomeOrg::SomeDomain::SomeCommand `GlobalOrganization.foobara_lookup(:SomeCommand)`
      # will return nil but
      # `GlobalOrganization.foobara_lookup(:SomeCommand, mode: Foobara::Namespace::LookupMode::RELAXED)`
      # will return SomeOrg::SomeDomain::SomeCommand even though we didn't specify the necessary prefixes
      # to navigate to it.
      RELAXED = :relaxed
      DIRECT = :direct
      STRICT = :strict
      ABSOLUTE = :absolute
      ABSOLUTE_SINGLE_NAMESPACE = :absolute_single_namespace
      CHILDREN_ONLY = :children_only

      ALL = [GENERAL, RELAXED, DIRECT, STRICT, ABSOLUTE, ABSOLUTE_SINGLE_NAMESPACE, CHILDREN_ONLY].freeze

      class << self
        def validate!(mode)
          unless ALL.include?(mode)
            # :nocov:
            raise ArgumentError, "Expected #{mode} to be one of #{ALL.map(&:inspect).join(",")}"
            # :nocov:
          end
        end
      end
    end
  end
end
