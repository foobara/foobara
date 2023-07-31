require "foobara/type/type_error"

module Foobara
  class Type
    class AttributeError < Type::TypeError
      class << self
        def context_schema
          {
            attribute_name: :symbol
          }
        end
      end

      attr_accessor :path

      def initialize(context:, path: [], **data)
        super(**data)

        self.context = context

        self.path = path
      end

      def attribute_name
        # TODO: feels awkward... something is not right
        # how is path actually set?
        path.last || context[:attribute_name]
      end

      def context_schema
        {
          path: :duck, # TODO: fix this up once there's an array type
          attribute_name: :symbol
        }
      end

      def eql?(other)
        super && other.is_a?(AttributeError) && attribute_name == other.attribute_name
      end
    end
  end
end
