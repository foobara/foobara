require "active_support/core_ext/string/inflections"
require "foobara/models/types/attributes_type"
require "foobara/models/types/integer_type"

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
    register_type(Types::AttributesType)
  end
end
