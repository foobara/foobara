module Foobara
  class Entity < DetachedEntity
    module Concerns
      module Types
        include Concern

        module ClassMethods
          def type_declaration(...)
            super.merge(type: :entity)
          end
        end
      end
    end
  end
end
