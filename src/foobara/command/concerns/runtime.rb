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

        attr_reader :outcome, :exception

        def run
          result = invoke_with_callbacks_and_transition(%i[
                                                          cast_and_validate_inputs
                                                          load_records
                                                          validate_records
                                                          validate
                                                          execute
                                                        ])

          result = process_result_using_result_schema(result)

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

        private

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
      end
    end
  end
end
