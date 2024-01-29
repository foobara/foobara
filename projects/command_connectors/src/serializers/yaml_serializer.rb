module Foobara
  module CommandConnectors
    module Serializers
      # TODO: move this to its own project
      class YamlSerializer < Serializer
        def serialize(object)
          YAML.dump(object)
        end

        def priority
          Priority::LOW
        end
      end
    end
  end
end
