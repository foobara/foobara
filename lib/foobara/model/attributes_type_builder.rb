require "foobara/model/schema_type_builder"

module Foobara
  class Model
    class AttributesTypeBuilder < SchemaTypeBuilder
      def direct_cast_ruby_classes
        ::Hash
      end
    end
  end
end
