module Foobara
  module Types
    class << self
      def global_registry
        @global_registry ||= Types::Registry.new("")
      end

      def reset_all
        remove_instance_variable("@global_registry") if instance_variable_defined?("@global_registry")
      end

      foobara_delegate :[], :[]=, :registered?, :register, to: :global_registry
    end
  end
end
