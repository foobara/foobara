require_relative "conditioned"

module Foobara
  module Callback
    module Registry
      class JoinedConditioned < Conditioned
        attr_accessor :first, :second

        foobara_delegate :possible_conditions, :possible_condition_keys, to: :first

        def initialize(first, second)
          self.first = first
          self.second = second

          super(possible_conditions)
        end

        def unioned_callback_set_for(...)
          super.union(
            first.unioned_callback_set_for(...).union(
              second.unioned_callback_set_for(...)
            )
          )
        end
      end
    end
  end
end
