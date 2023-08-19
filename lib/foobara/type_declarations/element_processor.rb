require "foobara/types/element_processor"

module Foobara
  module TypeDeclarations
    class ElementProcessor < Types::ElementProcessor
      include WithRegistries
    end
  end
end
