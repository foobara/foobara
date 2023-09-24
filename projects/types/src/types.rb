module Foobara
  module Types
    class << self
      def global_registry
        @global_registry ||= Types::Registry.new("")
      end

      foobara_delegate :[], :[]=, :registered?, :register, to: :global_registry
    end
  end
end
