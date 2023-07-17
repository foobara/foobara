module Foobara
  class Command
    module Concerns
      module Runtime
        extend ActiveSupport::Concern

        class CannotHaltWithoutAddingErrors < StandardError; end
        # TODO: can/should use throw/catch instead?
        class Halt < StandardError; end

        class_methods do
          def run(inputs)
            new(inputs).run
          end

          def run!(inputs)
            new(inputs).run!
          end
        end

        attr_reader :outcome, :error_collection, :exception

        def initialize
          @error_collection = ErrorCollection.new
        end

        delegate :has_errors?, :add_error, to: :error_collection

        def run
          result = invoke_with_callbacks_and_transition(%i[
                                                          cast_inputs
                                                          validate_inputs
                                                          load_records
                                                          validate_records
                                                          validate
                                                          execute
                                                        ])

          result = cast_result_using_result_schema(result)
          validate_result_using_result_schema(result)

          state_machine.succeed!

          @outcome = Outcome.success(result)
        rescue Halt
          if error_collection.empty?
            raise CannotHaltWithoutAddingErrors, "Cannot halt without adding errors first"
          end

          state_machine.fail!

          @outcome = Outcome.errors(error_collection)
        rescue => e
          @exception = e
          state_machine.error!
          raise
        end

        def success?
          outcome&.success?
        end

        def add_input_error(**args)
          error = InputError.new(**args)
          add_error(error)
          validate_error(error)
        end

        def add_runtime_error(**args)
          error = RuntimeError.new(**args)
          add_error(error)
          validate_error(error)
          halt!
        end

        def validate_error(error)
          symbol = error.symbol
          message = error.message
          context = error.context

          if !message.is_a?(String) || message.empty?
            raise "Bad error message, expected a string"
          end

          map = self.class.error_context_schema_map

          map = case error
                when RuntimeError
                  map[:runtime]
                when InputError
                  input = error.input

                  map[:input][input]
                else
                  raise "Unexpected error type for #{error}"
                end

          possible_error_symbols = map.keys
          context_schema = map[symbol]

          unless possible_error_symbols.include?(symbol)
            raise "Invalid error symbol #{symbol} expected one of #{possible_error_symbols}"
          end

          if context_schema.present?
            errors = context_schema.validation_errors(context.presence || {})
            # TODO: make real error class
            raise "Invalid context schema #{context}: #{errors}"
          elsif context.present?
            raise "There's no context schema declared for #{symbol}"
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
              halt! if has_errors?
            end
          end

          result
        end

        def cast_inputs
          Array.wrap(input_schema.casting_errors(raw_inputs)).each do |error|
            symbol = error.symbol
            message = error.message
            context = error.context

            input = context[:cast_to]

            add_input_error(input:, symbol:, message:, context:)
          end

          @inputs = input_schema.cast_from(raw_inputs)
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

        def abandon!
          state_machine.abandon!
          halt!
        end
      end
    end
  end
end
