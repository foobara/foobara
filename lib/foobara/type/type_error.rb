module Foobara
  class Type
    class TypeError < Foobara::Error
      attr_accessor :path

      def initialize(path: [], **opts)
        self.path = path
        super(**opts)
      end
    end
  end
end
