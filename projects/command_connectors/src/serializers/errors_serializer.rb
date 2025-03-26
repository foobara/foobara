module Foobara
  require_project_file("command_connectors", "serializer")

  module CommandConnectors
    module Serializers
      class ErrorsSerializer < Serializer
        def always_applicable?
          !request.outcome.success?
        end

        def serialize(errors)
          errors.map(&:to_h)
        end
      end
    end
  end
end
