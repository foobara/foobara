module Foobara
  module Models
    class Type
      class TypeConversionError < StandardError
        attr_accessor :errors

        def initialize(errors)
          self.errors = Array.wrap(errors)

          super(self.errors.map(&:message).join(", "))
        end
      end

      class << self
        def symbol
          name.demodulize.underscore.gsub(/_type$/, "").to_sym
        end

        def raise_type_conversion_error(object)
          error = Error.new(
            :"cannot_cast_to_#{symbol}",
            "Could not cast #{object.inspect} to #{symbol}",
            cast_to: symbol,
            value: object
          )

          raise TypeConversionError, error
        end
      end
    end
  end
end
