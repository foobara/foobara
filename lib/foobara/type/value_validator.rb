module Foobara
  class Type
    class ValueValidator < ValueProcessor
      def validation_errors(_value)
        raise "subclass responsibility"
      end

      def process_outcome(outcome)
        errors = validation_errors(outcome.result)

        Array.wrap(errors).each do |error|
          outcome.add_error(error)
        end
      end
    end
  end
end
