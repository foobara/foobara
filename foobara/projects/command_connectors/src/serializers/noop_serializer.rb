module Foobara
  module CommandConnectors
    module Serializers
      # TODO: move this to its own project
      class NoopSerializer < Serializer
        def serialize(object)
          object
        end

        def deserialize(object)
          object
        end

        def priority
          Priority::LOW
        end
      end
    end
  end
end
