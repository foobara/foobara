require "singleton"

module Foobara
  module Types
    class << self
      def reset_all
        remove_instance_variable("@global_registry") if instance_variable_defined?("@global_registry")
      end
    end
  end
end
