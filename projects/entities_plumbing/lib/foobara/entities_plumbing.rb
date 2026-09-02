module Foobara
  module EntitiesPlumbing
    class << self
      def install!
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::Transactions
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::Entities
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::EntityInputs
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::EntityErrorsType
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::EntityReflection
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::TransactionalRuntime

        if Foobara.project_installed?("command_connectors")
          # simplecov:disable
          install_command_connector_extension
          # simplecov:enable
        end
      end

      def new_project_added(new_project)
        if new_project.symbol == "command_connectors"
          install_command_connector_extension
        end
      end

      def add_persistence_states_and_transitions
        original_terminal_states = Command::StateMachine.terminal_states
        original_transition_map = Command::StateMachine.transition_map

        new_transition_map = {}

        new_transition_map[:initialized] = { open_transaction: :transaction_opened }
        new_transition_map[:transaction_opened] = { cast_and_validate_inputs: :inputs_casted_and_validated }
        new_transition_map[:inputs_casted_and_validated] = { load_records: :loaded_records }
        new_transition_map[:loaded_records] = { validate_records: :validated_records }
        new_transition_map[:validated_records] = { validate: :validated_execution }
        new_transition_map[:validated_execution] = {
          run_execute: original_transition_map[:validated_execution][:run_execute]
        }
        new_transition_map[:executing] = { commit_transaction: :transaction_committed }
        new_transition_map[:transaction_committed] = { succeed: :succeeded }

        new_transition_map[new_transition_map.keys] = {
          error: :errored,
          fail: :failed
        }

        [:succeeded, :errored, :failed].each do |state|
          new_transition_map[state] = original_transition_map[state]
        end

        Command::StateMachine.remove_all_callbacks
        Command::StateMachine.allow_recreating_callback_methods

        Command::StateMachine.set_transition_map(
          new_transition_map,
          terminal_states: original_terminal_states
        )
      end

      def install_command_connector_extension
        CommandConnector.singleton_class.prepend(
          Foobara::EntitiesPlumbing::CommandConnectorsExtension::ClassMethods
        )

        CommandConnector::Authenticator.include CommandConnector::AuthenticatorMethods
      end
    end

    add_persistence_states_and_transitions
  end
end

Foobara.project("entities_plumbing", project_path: "#{__dir__}/../..")
