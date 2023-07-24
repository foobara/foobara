require "foobara/type/value_transformer"

module Foobara
  class Type
    class Caster < ValueTransformer
      def applicable?(_value)
        raise "subclass responsibility"
      end

      def cast(_value)
        raise "subclass responsibility"
      end

      def transform(value)
        cast_from(value)
      end

      def applies_message(_value)
        raise "subclass responsibility"
      end
    end
  end
end
