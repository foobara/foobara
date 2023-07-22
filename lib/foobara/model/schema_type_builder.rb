require "foobara/model/type_builder"

module Foobara
  class Model
    class SchemaTypeBuilder < TypeBuilder
      class << self
        def for(schema)
          type = schema.type

          case type
          when :attributes
            AttributesTypeBuilder.new(schema)
          else
            PrimitiveTypeBuilder.new(type)
          end.to_type
        end
      end

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
