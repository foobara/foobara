module Foobara
  class Namespace
    # use-cases
    # 1. general: just general lookup. find it wherever the heck it might be
    #   children: y
    #   parent: y
    #   dependent: y
    # 2. direct: only this namespace. we want to know what this namespace directly owns
    #   children: n
    #   parent: n
    #   dependent: n
    # 3. strict: this namespace and dependent namespaces.
    #            We want to encapsulate and hide names that we haven't explicitly declared.
    #   children: n
    #   parent: n
    #   dependent: y
    # 4. absolute
    #   children: y
    #   parent: n
    #   dependent: n
    # TODO: don't we have an enumerated class/project for this?
    module LookupMode
      GENERAL = :general
      DIRECT = :direct
      STRICT = :strict
      ABSOLUTE = :absolute
      ALL = [GENERAL, DIRECT, STRICT, ABSOLUTE].freeze

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