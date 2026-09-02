module Foobara
  class Command
    class StateMachine < Foobara::StateMachine
      transitions = [
        :cast_and_validate_inputs,
        :validate,
        :run_execute,
        :succeed,
        :error,
        :fail,
        :reset
      ]

      terminal_states = [:succeeded, :errored, :failed]

      states = [
        :initialized,
        :inputs_casted_and_validated,
        :validated_execution,
        :executing,
      ] + terminal_states

      can_fail_states = states - terminal_states

      transition_map = {
        initialized: { cast_and_validate_inputs: :inputs_casted_and_validated },
        inputs_casted_and_validated: { validate: :validated_execution },
        validated_execution: { run_execute: :executing },
        executing: { succeed: :succeeded },
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
