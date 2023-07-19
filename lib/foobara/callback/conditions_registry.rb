require "foobara/callback/abstract_registry"

module Foobara
  module Callback
    class ConditionsRegistry < AbstractRegistry
      attr_accessor :possible_conditions, :possible_condition_keys, :callback_sets

      class InvalidConditions < StandardError; end

      def initialize(possible_conditions)
        super()
        self.callback_sets = {}
        self.possible_conditions = possible_conditions
        self.possible_condition_keys = possible_conditions.keys.map(&:to_s).sort.map(&:to_sym)
      end

      def specific_callback_set_for(**conditions)
        validate_conditions!(**conditions) # TODO: don't always have to validate this...
        key = condition_hash_to_callback_key(conditions)
        callback_sets[key] ||= Callback::Set.new
      end

      def unioned_callback_set_for(**conditions)
        any_set = specific_callback_set_for

        return set if conditions.blank?

        full_callback_key = condition_hash_to_callback_key(conditions)
        all_sets = callback_key_permutations(full_callback_key).map do |callback_key|
          callback_sets[callback_key]
        end.compact

        all_sets.inject(any_set) { |unioned, set| unioned.union(set) }
      end

      private

      def validate_conditions!(**conditions)
        raise InvalidConditions, "Expected a hash" unless conditions.is_a?(Hash)

        conditions.each_pair do |condition_name, condition_value|
          unless possible_condition_keys.include?(condition_name)
            raise InvalidConditions,
                  "Invalid condition name #{condition_name} expected one of #{possible_condition_keys}"
          end

          if !condition_value.nil? && !condition_value.is_a?(Symbol)
            possible_values = possible_conditions[condition_name]

            unless possible_values.include?(condition_value)
              raise InvalidConditions,
                    "Invalid condition value #{
                      condition_value
                    }: nil or one of #{possible_values} but got #{condition_value}"
            end
          end
        end
      end

      def condition_hash_to_callback_key(hash)
        possible_condition_keys.map do |condition|
          hash[condition]
        end
      end

      # we need to fetch callbacks for every possible way a specified condition could be omitted
      # so for example...
      # let's say possible conditions are :a, :b, :c
      # and we are given callbacks_for(:before, a: 1, c: 2)
      # well then b is always nil meaning b can be anything.
      # so we need the callbacks that were registered for the following keys...
      # [1, nil, 2] (conditions that were passed in, the most specific callbacks)
      # [1, nil, nil]
      # [nil, nil, 2]
      # [nil, nil, nil] (all :before callbacks for any conditions)
      # So what is the logic that generates this behavior?
      # What we could do is take the indexes of non-nil values and then create the powerset of those.
      # This would then create a list of which indexes to keep and which to nil out.
      def callback_key_permutations(full_callback_key)
        non_nil_indices = []

        full_callback_key.each.with_index do |condition_value, index|
          non_nil_indices << index if condition_value
        end

        Util.power_set(non_nil_indices).map do |indices_to_exclude|
          indices_to_exclude.each_with_object(full_callback_key.dup) do |index, condition_key|
            condition_key[index] = nil
          end
        end
      end
    end
  end
end
