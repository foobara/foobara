require_relative "joined_conditioned"

module Foobara
  module Callback
    module Registry
      class ChainedConditioned < Conditioned
        attr_accessor :other_conditions_registry

        def possible_conditions(...)
          other_conditions_registry.possible_conditions(...)
        end

        def possible_condition_keys(...)
          other_conditions_registry.possible_condition_keys(...)
        end

        def initialize(other_conditions_registry)
          self.other_conditions_registry = other_conditions_registry
          super(possible_conditions)
        end

        def unioned_callback_set_for(...)
          super.union(other_conditions_registry.unioned_callback_set_for(...))
        end
      end
    end
  end
end
