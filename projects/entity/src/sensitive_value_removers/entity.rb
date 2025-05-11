module Foobara
  class Entity < DetachedEntity
    module SensitiveValueRemovers
      class Entity < DetachedEntity::SensitiveValueRemovers::DetachedEntity
        def transform(record)
          if record.loaded? || record.created?
            super
          elsif record.persisted?
            # We will assume that we do not need to clean up the primary key itself as
            # we will assume we don't allow sensitive primary keys for now.
            # We use .new because the target_class should be a detached entity
            to_type.target_class.new(
              { record.class.primary_key_attribute => record.primary_key },
              { mutable: false, skip_validations: true }
            )
          else
            # :nocov:
            raise "Not sure what to do with a record that isn't loaded, created, or persisted"
            # :nocov:
          end
        end

        def build_method
          if to_type.extends_type?(BuiltinTypes[:entity])
            # TODO: test this code path
            # :nocov:
            :build
            # :nocov:
          else
            :new
          end
        end
      end
    end
  end
end
