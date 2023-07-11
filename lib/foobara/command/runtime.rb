module Foobara
  class Command
    module Runtime
      extend ActiveSupport::Concern

      class_methods do
        def run(inputs)
          new(inputs).run
        end

        def run!(inputs)
          new(inputs).run!
        end
      end

      attr_accessor :runtime_status, :raw_inputs, :inputs, :outcome

      def initialize(inputs)
        self.runtime_status = :unexecuted
        self.raw_inputs = inputs
        self.outcome = Outcome.new
      end

      def run
        self.runtime_status = :started

        validate_inputs

        if success?
          load_records
          validate_records
          outcome.result = execute
        end

        outcome
      end

      delegate :add_error, :success?, to: :outcome

      def validate_inputs
        outcome = input_schema.apply(raw_inputs)

        if outcome.success?
          self.inputs = outcome.result
        else
          outcome.each_error do |error|
            add_error(error)
          end
        end
      end

      def load_records
        # noop
      end

      def validate_records
        # noop
      end
    end
  end
end
