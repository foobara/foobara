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

      attr_accessor :raw_inputs, :inputs, :outcome

      def initialize(inputs)
        self.raw_inputs = inputs
        self.outcome = Outcome.new
      end

      def run
        outcome.result = invoke_with_callbacks_and_transition(%i[
                                                                validate_schema
                                                                cast_inputs
                                                                validate_inputs
                                                                load_records
                                                                validate_records
                                                                validate
                                                                execute
                                                              ])

        state_machine.succeed!
        outcome
      rescue Halt
        state_machine.fail!
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
      end

      def invoke_with_callbacks_and_transition(transition_or_transitions)
        result = nil

        if transition_or_transitions.is_a?(Array)
          transition_or_transitions.each do |transition|
            result = invoke_with_callbacks_and_transition(transition)
          end
        else
          transition = transition_or_transitions

          state_machine.perform_transition!(transition) do
            result = send(transition)
            halt! unless success?
          end
        end

        result
      end

      def cast_inputs
        Array.wrap(input_schema.casting_errors(raw_inputs)).each do |error|
          add_error(error)
        end

        self.inputs = input_schema.cast_from(raw_inputs)
      end

      def validate_inputs
        # TODO: check various validations like required, blank, etc
      end

      def load_records
        # noop
      end

      def validate_records
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
