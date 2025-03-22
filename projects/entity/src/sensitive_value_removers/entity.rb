module Foobara
  class Entity < DetachedEntity
    module SensitiveValueRemovers
      class Entity < DetachedEntity::SensitiveValueRemovers::DetachedEntity
        def transform(record)
          if record.loaded?
            super
          else
            type.target_class.thunk(record.id)
          end
        end

        def build_method
          :build
        end
      end
    end
  end
end
