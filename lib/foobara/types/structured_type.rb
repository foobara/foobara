require "foobara/types/type"

module Foobara
  module Types
    class StructuredType < Foobara::Types::Type
      attr_accessor :elements_processor

      def initialize(*args, elements_processor: {}, **opts)
        super(*args, **opts)
        self.elements_processor = elements_processor
      end

      def processors
        [*super, elements_processor].compact
      end
    end
  end
end
