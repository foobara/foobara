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
