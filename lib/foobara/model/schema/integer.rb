module Foobara
  class Model
    class Schema
      class Integer < Schema
        include Schema::Concerns::Primitive

        def max
          strict_schema[:max]
        end

        # how can we build this in a cleaner way so that validators can be more easily registered on types
        def to_h
          if max.present?
            super.merge(max:)
          else
            super
          end
        end
      end
    end
  end
end
