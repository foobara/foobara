module Foobara
  module Value
    class Transformer
      class << self
        def metadata
          @metadata ||= {}
        end
      end

      attr_accessor :declaration_data, :declaration_data_given

      def initialize(*args)
        args_count = args.size

        if args_count == 1
          self.declaration_data = args.first
          self.declaration_data_given = true
        elsif args_count != 0
          raise ArgumentError, "Expected 0 or 1 arguments containing the #{self.class.name} data"
        end
      end

      def declaration_data_given?
        declaration_data_given
      end

      def transform(_value)
        raise "subclass responsibility"
      end

      def process(value, _path)
        Outcome.success(transform(value))
      end

      def process_outcome(outcome, path)
        return outcome if outcome.is_a?(Value::HaltedOutcome)

        new_outcome = process(outcome.result, path)

        outcome.result = new_outcome.result

        new_outcome.each_error do |error|
          outcome.add_error(error)
        end

        outcome
      end

      def process!(value)
        outcome = process(value, [])

        if outcome.success?
          outcome.result
        else
          outcome.raise!
        end
      end

      # A transformer with no declaration data or with declaration data of false is considered to be
      # not applicable. Override this wherever different behavior is needed.
      # TODO: do any transformers really need this _value argument to determine applicability??
      def applicable?(_value)
        always_applicable?
      end

      # This means its applicable regardless of value to transform. Override if different behavior is needed.
      def always_applicable?
        declaration_data
      end
    end
  end
end
