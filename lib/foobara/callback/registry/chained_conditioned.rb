require "foobara/callback/registry/conditioned"

module Foobara
  module Callback
    module Registry
      class ChainedConditioned < Conditioned
        attr_accessor :other_conditions_registry

        class InvalidConditions < StandardError; end

        delegate :possible_conditions, :possible_condition_keys, to: :other_conditions_registry

        def initialize(other_conditions_registry)
          self.other_conditions_registry = other_conditions_registry
          super(possible_conditions)
        end

        def unioned_callback_set_for(**conditions)
          super.union(other_conditions_registry.unioned_callback_set_for(**conditions))
        end
      end
    end
  end
end
