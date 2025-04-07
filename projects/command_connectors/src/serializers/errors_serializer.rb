module Foobara
  require_project_file("command_connectors", "serializer")

  module CommandConnectors
    module Serializers
      class ErrorsSerializer < Serializer
        def applicable?(error_collection)
          if request.outcome.nil? || !request.outcome.success?
            error_collection.has_errors?
          end
        end

        def serialize(error_collection)
          errors = error_collection.errors
          errors.map(&:to_h)
        end
      end
    end
  end
end
