require "securerandom"

Foobara.require_project_file("value", "processor/runner")

module Foobara
  module Value
    class Transformer < Processor
      class Runner < Processor::Runner
        runner_methods :transform
      end

      class << self
        def foobara_manifest(to_include:)
          super.merge(processor_type: :transformer)
        end

        def error_classes
          []
        end

        def create(options)
          subclass(**options).instance
        end

        # TODO: make transform the first argument for convenience
        def subclass(name: nil, **options)
          arity_zero = %i[always_applicable? priority]
          arity_one = %i[applicable? transform]
          allowed = arity_zero + arity_one

          invalid_options = options.keys - allowed

          unless invalid_options.empty?
            # :nocov:
            raise ArgumentError, "Invalid options #{invalid_options} expected only #{allowed}"
            # :nocov:
          end

          name ||= "#{self.name}::Anon#{SecureRandom.hex}"

          unless name.include?(":")
            name = "#{self.name}::#{name}"
          end

          Util.make_class(name, self) do
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
