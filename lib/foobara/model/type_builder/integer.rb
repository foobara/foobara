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
          processors = base_type.value_processors

          if max.present?
            [*processors, Type::Validators::Integer::MaxExceeded.new(max)]
          else
            processors
          end
        end
      end
    end
  end
end
