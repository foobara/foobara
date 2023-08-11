require "active_support/core_ext/array/conversions"
require "singleton"

Foobara::Util.require_directory("#{__dir__}/types")

module Foobara
  # TODO: maybe rename this project "types" so that Types module can avoid taking up Type name that could be used by
  # the Type class
  module Types
  end
end
