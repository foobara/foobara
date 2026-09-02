module Foobara
  class Entity < DetachedEntity
    module NewPrepend
      # rubocop:disable-next Lint/UselessMethodDefinition
      def new(...)
        super
      end

      alias __private_new__ new

      # rubocop:disable-next Lint/DuplicateMethods
      def new(...)
        # simplecov:disable
        raise "Cannot initialize a #{name}. Use .create, .thunk, .loaded, or .build instead."
        # simplecov:enable
      end
    end
  end
end
