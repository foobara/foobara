module Foobara
  class Entity < DetachedEntity
    module SensitiveTypeRemovers
      class Entity < DetachedEntity::SensitiveTypeRemovers::DetachedEntity
      end
    end
  end
end
