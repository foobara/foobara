module Foobara
  module Models
    class Type
      class TypeConversionError < StandardError
      end

      class << self
        def symbol
          name.demodulize.underscore.gsub(/_type$/, "").to_sym
        end

        def raise_type_conversion_error
          raise TypeConversionError
        end
      end
    end
  end
end
