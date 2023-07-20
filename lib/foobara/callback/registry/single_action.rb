module Foobara
  module Callback
    module Registry
      class SingleAction < Base
        def specific_callback_set_for
          @specific_callback_set_for ||= Callback::Set.new
        end

        def unioned_callback_set_for
          specific_callback_set_for
        end
      end
    end
  end
end
