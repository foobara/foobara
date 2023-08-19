module Foobara
  module Value
    # TODO: this needs a better name
    class AttributeError < Error
      attr_accessor :path

      class << self
        def context_type_declaration
          {
            attribute_name: :symbol,
            value: :duck
          }
        end
      end

      def initialize(context:, path: [], **data)
        super(**data)

        self.context = context

        self.path = path
      end

      delegate :context_type_declaration, to: :class

      def attribute_name
        # TODO: feels awkward... something is not right
        # how is path actually set?
        path.last || context[:attribute_name]
      end

      def eql?(other)
        super && other.is_a?(AttributeError) && attribute_name == other.attribute_name
      end
    end
  end
end
