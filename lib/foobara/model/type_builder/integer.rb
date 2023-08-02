module Foobara
  class Model
    class TypeBuilder
      class Integer < TypeBuilder
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
      end
    end
  end
end
