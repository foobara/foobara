module Foobara
  class Model
    class Registry
      def initialize
        @type_classes = []
      end

      # Example...
      # register_type(:zip_code, :string, ZipCode)
      def register_type(type_class)
        @type_classes << type_class
      end

      def type_for(symbol)
        type_map[symbol]
      end

      def type_symbol?(symbol)
        type_map.key?(symbol)
      end

      def register_entity(model_class)
      end

      private

      def type_map
        @type_map ||= @type_classes.to_h { |type_class| [type_class.instance.symbol, type_class.instance] }
      end
    end
  end
end
