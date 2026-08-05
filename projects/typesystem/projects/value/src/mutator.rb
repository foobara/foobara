module Foobara
  module Value
    class Mutator < Processor
      class << self
        def foobara_manifest
          super.merge(processor_type: :mutator)
        end

        def error_classes
          []
        end
      end

      def mutate(_value)
        # simplecov:disable
        raise NotImplementedError
        # simplecov:enable
      end

      def process_value(value)
        mutate(value)
        Outcome.success(value)
      end
    end
  end
end
