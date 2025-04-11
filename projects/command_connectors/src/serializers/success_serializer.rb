module Foobara
  require_project_file("command_connectors", "serializer")

  module CommandConnectors
    module Serializers
      class SuccessSerializer < Serializer
        def always_applicable?
          request.outcome&.success?
        end
      end
    end
  end
end
