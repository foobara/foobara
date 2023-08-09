module Foobara
  module Value
    class Caster < Transformer
      def type_symbol
        @type_symbol ||= module_for(module_for(self.class)).name.underscore.to_sym
      end

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
        raise "subclass responsibility"
      end
    end
  end
end
