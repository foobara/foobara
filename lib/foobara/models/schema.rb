module Foobara
  class Models
    class Schema
      attr_accessor :raw_schema, :strict_schema

      def initialize(raw_schema)
        self.raw_schema = raw_schema

        desugarize!
        validate!
      end

      def type
        strict_schema[:type]
      end

      def desugarize!
        # TODO: need a real implementation
        self.strict_schema = raw_schema
      end

      def validate!
        # raise "not yet implemented"
      end

      def apply(_object)
        raise "not yet implemented"
      end
    end
  end
end
