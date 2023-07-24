module Foobara
  class Type
    class Validator
      # returns errors
      def validation_errors(_value)
        raise "subclass responsibility"
      end
    end
  end
end
