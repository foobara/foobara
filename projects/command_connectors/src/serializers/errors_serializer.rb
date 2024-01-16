module Foobara
  require_project_file("command_connectors", "serializer")

  module CommandConnectors
    module Serializers
      class ErrorsSerializer < Serializer
        # TODO: always_applicable? instead?
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
