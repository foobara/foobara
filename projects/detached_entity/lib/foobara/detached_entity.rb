module Foobara
  class DetachedEntity < Model
    abstract

    class << self
      # Need to override this otherwise we install Model twice
      def install!
      end
    end
  end
end
