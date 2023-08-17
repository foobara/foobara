require "active_support/core_ext/array/conversions"
require "singleton"

Foobara::Util.require_directory("#{__dir__}/types")

module Foobara
  module Types
    class << self
      def global_registry
        @global_registry ||= Types::Registry.new
      end

      delegate :[], :[]=, :registered?, :register, to: :global_registry
    end
  end
end
