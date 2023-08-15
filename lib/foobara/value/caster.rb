module Foobara
  module Value
    # TODO: do we really need these??  Can't just use a transformer?
    class Caster < Transformer
      def applicable?(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def applies_message(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def transform(value)
        cast(value)
      end

      def cast(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end
    end
  end
end
