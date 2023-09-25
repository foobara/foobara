module Foobara
  class Entity < Model
    module NewPrepend
      def new(...)
        super
      end

      alias __private_new__ new

      def new(...)
        raise "Cannot initialize a #{name}. Use .create, .thunk, .loaded, or .build instead."
      end
    end
  end
end
