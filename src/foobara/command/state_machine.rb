module Foobara
  class Command
    class StateMachine < Foobara::StateMachine
      transitions = %i[
        cast_and_validate_inputs
        load_records
        validate_records
        validate
        execute
        succeed
        error
        fail
        abandon
        reset
      ]

      terminal_states = %i[succeeded errored failed abandoned]

      states = %i[
        initialized
        inputs_casted_and_validated
        loaded_records
        validated_records
        validated_execution
        executing
      ] + terminal_states

      can_fail_states = states - terminal_states

      transition_map = {
        initialized: { cast_and_validate_inputs: :inputs_casted_and_validated },
        inputs_casted_and_validated: { load_records: :loaded_records },
        loaded_records: { validate_records: :validated_records },
        validated_records: { validate: :validated_execution },
        validated_execution: { execute: :executing },
        executing: { succeed: :succeeded },
        terminal_states => { reset: :initialized },
        can_fail_states => {
          error: :errored,
          fail: :failed,
          abandon: :abandoned
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
