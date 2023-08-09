module Foobara
  module Value
    class Error < Foobara::Error
      attr_accessor :path

      def initialize(path: [], **opts)
        self.path = path
        super(**opts)
      end

      delegate :context_type,
               to: :class
    end
  end
end
