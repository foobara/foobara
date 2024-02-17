require "singleton"

module Foobara
  module Types
    class << self
      def install!
        Foobara.foobara_add_category_for_instance_of(:type, Type)
      end
    end
  end
end
