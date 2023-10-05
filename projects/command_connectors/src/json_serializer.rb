module Foobara
  module CommandConnectors
    class JsonSerializer < Serializer
      def serialize(object)
        JSON.fast_generate(object)
      end

      def priority
        Priority::LOW
      end
    end
  end
end
