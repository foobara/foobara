module Foobara
  class Entity < DetachedEntity
    module Concerns
      module Types
        include Concern

        module ClassMethods
          def type_declaration(...)
            declaration = super

            declaration[:type] = :entity
            declaration.is_absolutified = true

            declaration
          end
        end
      end
    end
  end
end
