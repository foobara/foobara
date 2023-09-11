require "active_support/core_ext/array/conversions"
require "singleton"

Foobara::Util.require_directory("#{__dir__}/types")

module Foobara
  module Types
    class << self
      def global_registry
        @global_registry ||= Types::Registry.new("")
      end

      def reset_all
        remove_instance_variable("@global_registry") if instance_variable_defined?("@global_registry")
      end

      delegate :[], :[]=, :registered?, :register, to: :global_registry
    end
  end
end
