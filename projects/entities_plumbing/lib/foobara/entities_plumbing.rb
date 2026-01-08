require "foobara/command_connectors"

module Foobara
  module EntitiesPlumbing
  end
end

Foobara.project("entities_plumbing", project_path: "#{__dir__}/../..")

Foobara::CommandConnector.singleton_class.prepend(
  Foobara::EntitiesPlumbing::CommandConnectorsExtension::ClassMethods
)
