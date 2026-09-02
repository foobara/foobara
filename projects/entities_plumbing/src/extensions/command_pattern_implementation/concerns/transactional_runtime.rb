module Foobara
  module CommandPatternImplementation
    module Concerns
      module TransactionalRuntime
        private

        def _run_all_steps
          invoke_with_callbacks_and_transition(:open_transaction)

          Persistence::EntityBase.using_transactions(transactions) do
            invoke_with_callbacks_and_transition([
                                                   :cast_and_validate_inputs,
                                                   :load_records,
                                                   :validate_records,
                                                   :validate,
                                                   :run_execute,
                                                   :commit_transaction
                                                 ])
          end

          invoke_with_callbacks_and_transition(:succeed)
        rescue
          rollback_transaction
          raise
        end
      end
    end
  end
end
