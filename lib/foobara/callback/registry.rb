module Foobara
  module Callback
    class Registry
      attr_accessor :callbacks, :possible_conditions

      class InvalidConditions < StandardError; end

      ALLOWED_CALLBACK_TYPES = %i[before after around failure error].freeze

      def initialize(*possible_conditions)
        if possible_conditions.length == 1 && possible_conditions.first.is_a?(Array)
          possible_conditions = possible_conditions.first
        end

        self.possible_conditions = possible_conditions.map(&:to_s).sort.map(&:to_sym)
        self.callbacks = {}
      end

      def register_callback(type, **conditions, &callback_block)
        validate_type!(type)
        validate_conditions!(**conditions)

        required_non_keyword_arity = callback_block.parameters.count { |(param_type, _name)| param_type == :req }

        if type == :around
          # must have exactly one non-keyword required parameter to accept the do_it proc
          if required_non_keyword_arity != 1
            raise "around callbacks must take exactly one argument which will be the do_it proc"
          end
        elsif required_non_keyword_arity != 0
          raise "#{type} callback should take exactly 0 arguments"
        end

        key = condition_hash_to_callback_key(conditions)
        callbacks_for_key = callbacks[type] ||= {}
        callback_blocks = callbacks_for_key[key] ||= []

        callback_blocks << callback_block
      end

      def callbacks_for(type, **conditions)
        validate_type!(type)
        validate_conditions!(**conditions)

        callbacks_for_type = callbacks[type]

        return [] if callbacks_for_type.blank?

        full_callback_key = condition_hash_to_callback_key(conditions)
        callback_key_permutations(full_callback_key).map do |callback_key|
          callbacks_for_type[callback_key]
        end.compact.flatten
      end

      def before(**conditions, &)
        register_callback(:before, **conditions, &)
      end

      def after(**conditions, &)
        register_callback(:after, **conditions, &)
      end

      def around(**conditions, &)
        register_callback(:around, **conditions, &)
      end

      # these two seem to have awkward names
      def failure(**conditions, &)
        register_callback(:failure, **conditions, &)
      end

      def error(**conditions, &)
        register_callback(:error, **conditions, &)
      end

      def has_callbacks?(type, **conditions)
        callbacks_for(type, **conditions).present?
      end

      def has_before_callbacks?(**conditions)
        has_callbacks?(:before, **conditions)
      end

      def has_after_callbacks?(**conditions)
        has_callbacks?(:after, **conditions)
      end

      def has_around_callbacks?(**conditions)
        has_callbacks?(:around, **conditions)
      end

      def has_error_callbacks?(**conditions)
        has_callbacks?(:error, **conditions)
      end

      def has_failure_callbacks?(**conditions)
        has_callbacks?(:failure, **conditions)
      end

      private

      def validate_type!(type)
        unless ALLOWED_CALLBACK_TYPES.include?(type)
          raise "bad type #{type} expected one of #{ALLOWED_CALLBACK_TYPES}"
        end
      end

      def validate_conditions!(**conditions)
        raise InvalidConditions, "Expected a hash" unless conditions.is_a?(Hash)

        conditions.each_pair do |condition_name, condition_value|
          unless possible_conditions.include?(condition_name)
            raise InvalidConditions, "Invalid condition name #{condition_name} expected one of #{possible_conditions}"
          end

          if !condition_value.nil? && !condition_value.is_a?(Symbol)
            raise InvalidConditions,
                  "Invalid condition value #{condition_value}: expected Symbol or nil but got #{condition_value.class}"
          end
        end
      end

      def condition_hash_to_callback_key(hash)
        possible_conditions.map do |condition|
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

        power_set(non_nil_indices).map do |indices_to_exclude|
          indices_to_exclude.each_with_object(full_callback_key.dup) do |index, condition_key|
            condition_key[index] = nil
          end
        end
      end

      def power_set(array)
        return [[]] if array.empty?

        head, *tail = array
        subsets = power_set(tail)
        subsets + subsets.map { |subset| [head, *subset] }
      end
    end
  end
end
