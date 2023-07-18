module Foobara
  module Callback
    class ChainedRegistry
      attr_accessor :callbacks, :possible_conditions, :registries

      class InvalidConditions < StandardError; end

      ALLOWED_CALLBACK_TYPES = %i[before after around failure error].freeze

      delegate :possible_conditions,
               :register_callback,
               :before,
               :after,
               :around,
               :failure,
               :error,
               :has_callbacks?,
               :has_before_callbacks?,
               :has_after_callbacks?,
               :has_around_callbacks?,
               :has_error_callbacks?,
               :has_failure_callbacks?,
               to: :first_registry

      def initialize(other_registry)
        self.registries = [Registry.new(other_registry.possible_conditions), other_registry]
      end

      def first_registry
        registries.first
      end

      def callbacks_for(type, **conditions)
        registries.map do |registry|
          registry.callbacks_for(type, **conditions)
        end.flatten
      end

      %i[
        has_callbacks?
        has_before_callbacks?
        has_after_callbacks?
        has_around_callbacks?
        has_error_callbacks?
        has_failure_callbacks?
      ].each do |method_name|
        define_method method_name do |*args, **conditions|
          registries.any? do |registry|
            registry.send(method_name, *args, **conditions)
          end
        end
      end
    end
  end
end
