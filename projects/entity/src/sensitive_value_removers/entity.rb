module Foobara
  class Entity < DetachedEntity
    module SensitiveValueRemovers
      class Entity < DetachedEntity::SensitiveValueRemovers::DetachedEntity
        def transform(record)
          sanitized_record = super

          sanitized_record.is_loaded = record.loaded?
          sanitized_record.is_persisted = record.persisted?

          sanitized_record
        end

        def build_method
          :build
        end
      end
    end
  end
end
