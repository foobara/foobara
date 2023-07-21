require "foobara/model/schema_type_builder"

module Foobara
  class Model
    class AttributesTypeBuilder < SchemaTypeBuilder
      def ruby_class
        ::Hash
      end
    end
  end
end
