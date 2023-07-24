module Foobara
  class Type
    class ValueValidator < ValueProcessor
      def validation_errors(_value)
        raise "subclass responsibility"
      end

      def process(outcome)
        validation_errors(outcome.result).each do |error|
          outcome.add_error(error)
        end
      end
    end
  end
end
