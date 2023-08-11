require "foobara/value/attribute_error"

module Foobara
  module Value
    # This doesn't feel right as cannot cast error might have nothing to do with an attribute
    # TODO: fix this
    class CannotCastError < AttributeError
      class << self
        def context_type
          # TODO: hmmmm this is a backwards dependency here, dang...
          # TODO: fix this...
          @context_type ||= Model::Schemas::Attributes.new(context_schema).to_type
        end

        # Value will always need to be a duck but cast_to: should probably be the relevant
        # type-declaration.  This means it shouldn't come from the class but rather the processor
        def context_schema
          {
            cast_to: :duck,
            value: :duck,
            attribute_name: :symbol
          }
        end
      end

      def initialize(**opts)
        super(**opts.merge(symbol: :cannot_cast))
      end
    end
  end
end
