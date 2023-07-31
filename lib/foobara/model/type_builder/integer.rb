module Foobara
  class Model
    class TypeBuilder
      class Integer < TypeBuilder
        delegate :max, to: :schema

        def to_type
          Type.new(**to_args)
        end

        def to_args
          {
            casters:,
            value_processors:
          }
        end

        def base_type
          @base_type ||= Type[:integer]
        end

        def casters
          base_type.casters
        end

        def value_processors
          processors = base_type.value_processors.dup

          Schema.validators_for_type(:integer).each_pair do |validator_symbol, validator_class|
            if schema.strict_schema.key?(validator_symbol)
              processors << validator_class.new(schema.strict_schema[validator_symbol])
            end
          end

          processors
        end
      end
    end
  end
end
