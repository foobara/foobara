module Foobara
  module ModelPlumbing
    module DomainMapperExtension
      def object_to_type(object)
        if object.is_a?(::Class) && object < Foobara::Model
          object.model_type
        else
          super
        end
      end
    end
  end
end
