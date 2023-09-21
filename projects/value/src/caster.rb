module Foobara
  module Value
    # TODO: do we really need these??  Can't just use a transformer?
    class Caster < Transformer
      class << self
        def manifest
          super.merge(processor_type: :caster)
        end

        def requires_declaration_data?
          false
        end

        def create(options)
          subclass(options).instance
        end

        def subclass(options)
          arity_zero = %i[name applies_message]
          arity_one = %i[applicable? cast]
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

      def applicable?(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def applies_message
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def transform(value)
        cast(value)
      end

      def cast(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end
    end
  end
end
