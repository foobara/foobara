module Foobara
  module Callback
    class SingleEventRegistry < AbstractRegistry
      def specific_callback_set_for
        @specific_callback_set_for ||= Callback::Set.new
      end

      def unioned_callback_set_for
        specific_callback_set_for
      end
    end
  end
end
