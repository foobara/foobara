module Foobara
  class Type
    class Transformer
      # returns an Outcome
      def transform(_value)
        raise "subclass responsibility"
      end
    end
  end
end
