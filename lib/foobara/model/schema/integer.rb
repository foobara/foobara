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
          h = super

          Schema.validators_for_type(:integer).each_key do |validator_symbol|
            value = strict_schema[validator_symbol]
            h = h.merge(validator_symbol => value)
          end

          h
        end
      end
    end
  end
end
