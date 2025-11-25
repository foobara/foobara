module Foobara
  module CommandConnectors
    module Serializers
      # TODO: move this to its own project
      class JsonSerializer < Serializer
        def serialize(object)
          JSON.fast_generate(object)
        end

        def deserialize(string)
          JSON.parse(string)
        end

        def priority
          Priority::LOW
        end
      end
    end
  end
end
