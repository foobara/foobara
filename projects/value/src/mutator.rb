module Foobara
  module Value
    class Mutator < Processor
      class << self
        def foobara_manifest(to_include: Set.new, remove_sensitive: false)
          super.merge(processor_type: :mutator)
        end

        def error_classes
          []
        end
      end

      def mutate(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def process_value(value)
        if applicable?(value)
          mutate(value)
        end

        Outcome.success(value)
      end
    end
  end
end
