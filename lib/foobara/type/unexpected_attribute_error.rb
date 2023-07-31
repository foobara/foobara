require "foobara/type/attribute_error"

module Foobara
  class Type
    class UnexpectedAttributeError < AttributeError
      class << self
        def symbol
          :unexpected_attribute
        end
      end
    end
  end
end
