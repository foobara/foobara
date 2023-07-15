module Foobara
  class Command
    class StateMachine < Foobara::StateMachine
      transitions = %i[
        validate_schema
        cast_inputs
        validate_inputs
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
        validated_schema
        casted_inputs
        validated_inputs
        loaded_records
        validated_records
        validated_execution
        executing
      ] + terminal_states

      can_fail_states = states - terminal_states

      transition_map = {
        initialized: { validate_schema: :validated_schema },
        validated_schema: { cast_inputs: :casted_inputs },
        casted_inputs: { validate_inputs: :validated_inputs },
        validated_inputs: { load_records: :loaded_records },
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
