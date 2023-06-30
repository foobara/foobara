require "foobara/models/types/integer"
require "active_support/core_ext/string/inflections"

module Foobara
  module Models
    class << self
      attr_accessor :types

      def register_type(type)
        types[type.symbol] = type
      end
    end

    self.types = {}

    register_type(Types::IntegerType)
  end
end
