module Foobara
  class Entity < DetachedEntity
    module Concerns
      module Mutations
        include Concern

        module ClassMethods
        end
      end
    end
  end
end
