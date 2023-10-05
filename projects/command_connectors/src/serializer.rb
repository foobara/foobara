module Foobara
  module CommandConnectors
    class Serializer < Value::Transformer
      def request
        declaration_data
      end

      def transform(object)
        serialize(object)
      end
    end
  end
end
