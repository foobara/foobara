require_relative "conditioned"

module Foobara
  module Callback
    module Registry
      class JoinedConditioned < Conditioned
        attr_accessor :first, :second

        def possible_conditions
          first.possible_conditions
        end

        def possible_condition_keys
          first.possible_condition_keys
        end

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
