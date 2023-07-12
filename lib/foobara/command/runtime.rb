module Foobara
  class Command
    module Runtime
      extend ActiveSupport::Concern

      class Halt < StandardError; end

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

        validate_schema
        cast_inputs
        validate_inputs
        load_records
        validate_records

        validate

        halt! unless success?

        outcome.result = execute

        outcome
      rescue Halt
        outcome
      end

      delegate :add_error, :success?, to: :outcome

      def validate_schema
        halt! unless success?

        input_schema.schema_validation_errors.each do |error|
          add_error(error)
        end
      end

      def cast_inputs
        halt! unless success?

        Array.wrap(input_schema.casting_errors(raw_inputs)).each do |error|
          add_error(error)
        end

        self.inputs = input_schema.cast_from(raw_inputs)
      end

      def validate_inputs
        halt! unless success?
        # TODO: check various validations like required, blank, etc
      end

      def load_records
        halt! unless success?
        # noop
      end

      def validate_records
        halt! unless success?
        # noop
      end

      def validate
        # can override if desired, default is a no-op
      end

      def halt!
        raise Halt
      end
    end
  end
end
