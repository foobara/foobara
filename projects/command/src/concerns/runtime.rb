module Foobara
  class Command
    module Concerns
      module Runtime
        include Concern

        class CannotHaltWithoutAddingErrors < StandardError; end
        class Halt < StandardError; end

        module ClassMethods
          def run(...)
            new(...).run
          end

          def run!(...)
            new(...).run!
          end

          def define_command_named_function
            command_class = self
            convenience_method_name = Foobara::Util.non_full_name(command_class)
            containing_module = Foobara::Util.module_for(command_class) || Object

            if containing_module.is_a?(::Class)
              containing_module.singleton_class.define_method convenience_method_name do |*args, **opts, &block|
                command_class.run!(*args, **opts, &block)
              end

              containing_module.define_method convenience_method_name do |*args, **opts, &block|
                command_class.run!(*args, **opts, &block)
              end
            else
              containing_module.module_eval do
                module_function

                define_method convenience_method_name do |*args, **opts, &block|
                  command_class.run!(*args, **opts, &block)
                end
              end
            end
          end

          def undefine_command_named_function
            command_class = self
            convenience_method_name = Foobara::Util.non_full_name(command_class)
            containing_module = Foobara::Util.module_for(command_class) || Object

            return unless containing_module.respond_to?(convenience_method_name)

            containing_module.singleton_class.undef_method convenience_method_name

            if containing_module.is_a?(::Class)
              containing_module.undef_method convenience_method_name
            end
          end
        end

        attr_reader :outcome, :exception

        def run!
          run.result!
        end

        def run
          Foobara::Namespace.use self.class do
            invoke_with_callbacks_and_transition(:open_transaction)

            invoke_with_callbacks_and_transition_in_transaction(%i[
                                                                  cast_and_validate_inputs
                                                                  load_records
                                                                  validate_records
                                                                  validate
                                                                  run_execute
                                                                  commit_transaction
                                                                ])

            invoke_with_callbacks_and_transition(:succeed)
          end

          @outcome
        rescue Halt
          rollback_transaction

          return outcome if state_machine.currently_errored?

          if error_collection.empty?
            # :nocov:
            raise CannotHaltWithoutAddingErrors, "Cannot halt without adding errors first. " \
                                                 "Either add errors or use error! transition instead."
            # :nocov:
          end

          state_machine.fail!

          @outcome = Outcome.errors(error_collection)
        rescue => e
          @exception = e
          rollback_transaction
          state_machine.error!
          raise
        end

        def success?
          outcome&.success?
        end

        def run_execute
          result = process_result_using_result_type(execute)
          @outcome = Outcome.success(result)
        end

        def execute
        end

        def succeed
          # noop but for now helpful for carrying out state transition
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

        private

        def invoke_with_callbacks_and_transition_in_transaction(transition_or_transitions)
          Persistence::EntityBase.using_transactions(transactions) do
            invoke_with_callbacks_and_transition(transition_or_transitions)
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
      end
    end
  end
end
