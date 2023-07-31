require "foobara/model/attribute_error"

module Foobara
  # TODO: this is the wrong namespace! fix this
  class UnexpectedAttributeError < AttributeError
    class << self
      def symbol
        :unexpected_attributes
      end
    end
  end
end
