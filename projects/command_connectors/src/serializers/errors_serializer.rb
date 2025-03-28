module Foobara
  require_project_file("command_connectors", "serializer")

  module CommandConnectors
    module Serializers
      class ErrorsSerializer < Serializer
        def always_applicable?
          !request.outcome.success?
        end

        def serialize(error_collection)
          errors = error_collection.errors
          errors.map(&:to_h)
        end
      end
    end
  end
end
