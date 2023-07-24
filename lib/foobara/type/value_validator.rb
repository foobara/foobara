module Foobara
  class Type
    class ValueValidator < ValueProcessor
      def validation_errors(_value)
        raise "subclass responsibility"
      end

      def process(value)
        errors = validation_errors(value)

        if errors.blank?
          Outcome.success(value)
        else
          Outcome.errors(errors)
        end
      end
    end
  end
end
