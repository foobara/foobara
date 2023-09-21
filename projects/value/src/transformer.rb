Foobara.require_file("value", "processor")
Foobara.require_file("value", "processor/runner")

module Foobara
  module Value
    class Transformer < Processor
      class Runner < Processor::Runner
        runner_methods :transform
      end

      class << self
        def manifest
          super.merge(processor_type: :transformer)
        end

        def error_classes
          []
        end

        def create(options)
          subclass(options).instance
        end

        def subclass(options)
          arity_zero = %i[name always_applicable? priority]
          arity_one = %i[applicable? transform]
          allowed = arity_zero + arity_one

          invalid_options = options.keys - allowed

          if invalid_options.present?
            # :nocov:
            raise ArgumentError, "Invalid options #{invalid_options} expected only #{allowed}"
            # :nocov:
          end

          Class.new(self) do
            arity_one.each do |method_name|
              if options.key?(method_name)
                method = options[method_name]

                define_method method_name do |value|
                  method.call(value)
                end
              end
            end

            arity_zero.each do |method_name|
              if options.key?(method_name)
                value = options[method_name]

                define_method method_name do
                  value
                end
              end
            end
          end
        end
      end

      def transform(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def process_value(value)
        if applicable?(value)
          value = transform(value)
        end

        Outcome.success(value)
      end
    end
  end
end
