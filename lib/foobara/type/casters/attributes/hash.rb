module Foobara
  class Type
    class Attributes < Type
      module Casters
        # TODO: delete this class. This is not a sustainable solution. Just here to get the suite green for now.
        class Hash < Caster
          def cast_from(value)
            Outcome.success(value)
          end
        end
      end
    end
  end
end
