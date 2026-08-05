module Foobara
  class Entity < DetachedEntity
    module NewPrepend
      # rubocop:disable Lint/UselessMethodDefinition
      def new(...)
        super
      end
      # rubocop:enable Lint/UselessMethodDefinition

      alias __private_new__ new

      # rubocop:disable Lint/DuplicateMethods
      def new(...)
        # simplecov:disable
        raise "Cannot initialize a #{name}. Use .create, .thunk, .loaded, or .build instead."
        # simplecov:enable
      end
      # rubocop:enable Lint/DuplicateMethods
    end
  end
end
