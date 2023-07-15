module Foobara
  module Models
    class << self
      attr_accessor :types

      def register_type(type)
        types[type.symbol] = type
      end
    end

    self.types = {}

    register_type(Types::IntegerType.new)
    register_type(Types::AttributesType.new)
  end
end
