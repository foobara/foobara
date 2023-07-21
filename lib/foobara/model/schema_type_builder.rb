require "foobara/model/type_builder"

module Foobara
  class Model
    class SchemaTypeBuilder < TypeBuilder
      attr_accessor :schema

      def initialize(schema)
        self.schema = schema
        super()
      end

      def symbol
        @symbol ||= schema.type
      end
    end
  end
end
