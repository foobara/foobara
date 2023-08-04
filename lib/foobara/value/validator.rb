module Foobara
  module Value
    class Validator < Processor
      class << self
        def primary_proc_method
          :validation_errors
        end
      end

      def validation_errors(_value)
        raise "subclass responsibility"
      end

      def call(value)
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
