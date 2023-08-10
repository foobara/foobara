require "foobara/value/attribute_error"

module Foobara
  module Type
    class UnexpectedAttributeError < Value::AttributeError
      class << self
        def symbol
          :unexpected_attribute
        end
      end
    end
  end
end
