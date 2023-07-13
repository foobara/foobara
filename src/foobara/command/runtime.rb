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

        state_machine.execute!
        success? ? state_machine.succeed! : state_machine.fail!

        outcome
      rescue Halt
        outcome
      rescue
        state_machine.error!
        raise
      end

      delegate :add_error, :success?, :has_errors?, to: :outcome

      def validate_schema
        input_schema.schema_validation_errors.each do |error|
          add_error(error)
        end

        success? ? state_machine.validate_schema! : halt!
      end

      def cast_inputs
        halt! unless success?

        Array.wrap(input_schema.casting_errors(raw_inputs)).each do |error|
          add_error(error)
        end

        self.inputs = input_schema.cast_from(raw_inputs)

        success? ? state_machine.cast_inputs! : halt!
      end

      def validate_inputs
        # TODO: check various validations like required, blank, etc
        success? ? state_machine.validate_inputs! : halt!
      end

      def load_records
        success? ? state_machine.load_records! : halt!
        # noop
      end

      def validate_records
        success? ? state_machine.validate_records! : halt!
        # noop
      end

      def validate
        # can override if desired, default is a no-op
        success? ? state_machine.validate! : halt!
      end

      def halt!
        raise Halt
      end
    end
  end
end
