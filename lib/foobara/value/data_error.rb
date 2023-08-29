module Foobara
  module Value
    class DataError < Error
      attr_accessor :path

      def initialize(path: [], **data)
        super(**data)

        self.path = path
      end

      def attribute_name
        # TODO: feels awkward... something is not right
        # how is path actually set?
        path.last || context[:attribute_name]
      end

      def eql?(other)
        super && other.is_a?(DataError) && attribute_name == other.attribute_name
      end
    end
  end
end
