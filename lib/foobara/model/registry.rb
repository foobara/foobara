module Foobara
  class Model
    class Registry
      attr_accessor :types, :entities

      def initialize
        self.types = {}
        self.entities = {}
      end

      # Example...
      # register_type(:zip_code, :string, ZipCode)
      def register_type(type_class)
        types[type_class.symbol] = type_class
      end

      def register_entity(model_class)
      end
    end
  end
end
