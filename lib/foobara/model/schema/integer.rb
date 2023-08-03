module Foobara
  class Model
    class Schema
      class Integer < Schema
      end

      Integer.register_validator(Type::Validators::Integer::MaxExceeded)
      Integer.register_validator(Type::Validators::Integer::BelowMinimum)
    end
  end
end
