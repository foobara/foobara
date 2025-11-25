module Foobara
  module CommandConnectors
    class Serializer < Value::Transformer
      class << self
        def serializer_from_symbol(symbol)
          Util.descendants(Serializer).find do |klass|
            name = Util.non_full_name(klass)
            name = name.gsub(/Serializer$/, "")
            name = Util.underscore(name)

            symbol.to_s == name
          end
        end
      end

      def request
        declaration_data
      end

      def initialize(declaration_data = {})
        super
      end

      def transform(object)
        serialize(object)
      end
    end
  end
end
