module Foobara
  require_relative "../serializer"

  module CommandConnectors
    module Serializers
      class SuccessSerializer < Serializer
        def always_applicable?
          # Why is the serializer coupled to a request???
          request.outcome&.success?
        end
      end
    end
  end
end
