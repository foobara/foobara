module Foobara
  module Value
    class DataError < Error
      class << self
        def category
          :data
        end
      end

      def initialize(message: nil, symbol: nil, context: {}, path: nil)
        args = { message:, symbol:, context:, path: }.compact
        super(**args.merge(category: self.class.category))
      end

      def attribute_name
        # TODO: feels awkward... something is not right
        # how is path actually set?
        path.last || context[:attribute_name]
      end

      def eql?(other)
        # TODO: this doesn't feel right at all...
        super && other.is_a?(DataError) && path == other.path
      end
    end
  end

  DataError = Value::DataError
end
