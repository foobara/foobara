module Foobara
  class Type
    class ValueProcessor
      attr_accessor :processor_data

      def initialize(processor_data)
        self.processor_data = processor_data
      end

      def applicable?(_value)
        true
      end

      def process(_value, _path)
        raise "subclass responsibility"
      end

      def process_outcome(old_outcome, path)
        new_outcome = process(old_outcome.result, path)

        unless old_outcome.success?
          old_outcome.each_error do |error|
            new_outcome.add_error(error)
          end
        end

        new_outcome
      end

      def error_halts_processing?
        false
      end
    end
  end
end
