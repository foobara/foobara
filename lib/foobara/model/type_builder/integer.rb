module Foobara
  class Model
    class TypeBuilder
      class Integer < TypeBuilder
        # TODO: can we eliminate this??
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
