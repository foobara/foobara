module Foobara
  class Command
    class StateMachine < Foobara::StateMachine
      transitions = [
        :open_transaction,
        :cast_and_validate_inputs,
        :load_records,
        :validate_records,
        :validate,
        :run_execute,
        :commit_transaction,
        :succeed,
        :error,
        :fail,
        :reset
      ]

      terminal_states = [:succeeded, :errored, :failed]

      states = [
        :initialized,
        :transaction_opened,
        :inputs_casted_and_validated,
        :loaded_records,
        :validated_records,
        :validated_execution,
        :executing,
        :transaction_committed
      ] + terminal_states

      can_fail_states = states - terminal_states

      transition_map = {
        initialized: { open_transaction: :transaction_opened },
        transaction_opened: { cast_and_validate_inputs: :inputs_casted_and_validated },
        inputs_casted_and_validated: { load_records: :loaded_records },
        loaded_records: { validate_records: :validated_records },
        validated_records: { validate: :validated_execution },
        validated_execution: { run_execute: :executing },
        executing: { commit_transaction: :transaction_committed },
        transaction_committed: { succeed: :succeeded },
        terminal_states => { reset: :initialized },
        can_fail_states => {
          error: :errored,
          fail: :failed
        }
      }

      set_transition_map(
        transition_map,
        states:,
        terminal_states:,
        transitions:
      )
    end
  end
end
