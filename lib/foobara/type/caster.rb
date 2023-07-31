require "foobara/type/value_transformer"

module Foobara
  class Type
    class Caster < ValueTransformer
      def type_symbol
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def applicable?(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def cast(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def applies_message(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end
    end
  end
end
