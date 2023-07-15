module Foobara
  class Command
    module Schemas
      extend ActiveSupport::Concern

      class_methods do
        def input_schema(*args)
          if args.empty?
            @input_schema
          else
            raw_input_schema = args.first
            @input_schema = Foobara::Models::Schema.new(raw_input_schema)
          end
        end

        def raw_input_schema
          input_schema.raw_schema
        end

        def strict_input_schema
          input_schema.strict_schema
        end
      end
    end

    delegate :input_schema, :raw_input_schema, :strict_input_Schema, to: :class

    def method_missing(method_name, *args, &)
      if respond_to_missing?(method_name)
        inputs[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, private = false)
      inputs&.key?(method_name) || super
    end
  end
end
