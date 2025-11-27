require "singleton"

module Foobara
  module Types
    class << self
      def install!
        Namespace.global.foobara_add_category_for_instance_of(:type, Type)
      end
    end
  end
end

Foobara.project("types", project_path: "#{__dir__}/../..")
