require "active_support/concern"
require "active_support/core_ext/array/wrap"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/string/inflections"

# TODO: break these out into separate gems instead of simulating it here
require "foobara/common"
require "foobara/value"
require "foobara/enumerated"
require "foobara/callback"
require "foobara/state_machine"
require "foobara/types"
require "foobara/type_declarations"
require "foobara/builtin_types"
require "foobara/command"
require "foobara/domain"

module Foobara
  class << self
    # TODO: rename this to manifest...
    # TODO: come up with a way to change a type's manifest... Or maybe treat Model very differently?
    def manifest
      all_organizations.map(&:manifest_hash).inject(:merge)
    end

    def all_organizations
      Organization.all
    end

    def all_domains
      Domain.all.values
    end

    def all_commands
      Command.all
    end

    def all_types
      all_namespaces.map(&:all_types).flatten
    end

    def all_namespaces
      [*all_domains.map(&:type_namespace), TypeDeclarations::Namespace.global]
    end

    def reset_alls
      Foobara::Domain.reset_all
      Foobara::Model.reset_all
      Foobara::Command.reset_all
      Foobara::Organization.reset_all
      Foobara::Types.reset_all
      Foobara::TypeDeclarations.reset_all
      Foobara::BuiltinTypes.reset_all
    end
  end
end
