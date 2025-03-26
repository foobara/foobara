module Foobara
  class Entity < DetachedEntity
    module SensitiveValueRemovers
      class Entity < DetachedEntity::SensitiveValueRemovers::DetachedEntity
        def transform(record)
          if record.loaded? || record.created?
            sanitized_record = super

            sanitized_record.is_loaded = record.loaded?
            sanitized_record.is_persisted = record.persisted?

            sanitized_record
          elsif record.persisted?
            # We will assume that we do not need to clean up the primary key itself as
            # we will assume we don't allow sensitive primary keys for now.
            sanitized_record = to_type.target_class.build(record.class.primary_key_attribute => record.primary_key)

            sanitized_record.is_persisted = true
            sanitized_record.is_loaded = false
            sanitized_record.is_built = false

            sanitized_record
          else
            # :nocov:
            raise "Not sure what to do with a record that isn't loaded, created, or persisted"
            # :nocov:
          end
        end

        def build_method
          :build
        end
      end
    end
  end
end
