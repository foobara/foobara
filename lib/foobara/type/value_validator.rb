module Foobara
  class Type
    class ValueValidator < ValueProcessor
      def validation_errors(_value)
        raise "subclass responsibility"
      end
    end
  end
end
