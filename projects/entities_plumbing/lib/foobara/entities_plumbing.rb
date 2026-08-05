module Foobara
  module EntitiesPlumbing
    class << self
      def install!
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::Transactions
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::Entities
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::EntityInputs
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::EntityErrorsType
        CommandPatternImplementation.include CommandPatternImplementation::Concerns::EntityReflection

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

      def install_command_connector_extension
        CommandConnector.singleton_class.prepend(
          Foobara::EntitiesPlumbing::CommandConnectorsExtension::ClassMethods
        )

        CommandConnector::Authenticator.include CommandConnector::AuthenticatorMethods
      end
    end
  end
end

Foobara.project("entities_plumbing", project_path: "#{__dir__}/../..")
