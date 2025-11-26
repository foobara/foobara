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
            thunkish = to_type.target_class.send(build_method, record.class.primary_key_attribute => record.primary_key)
            thunkish.skip_validations = true
            thunkish.mutable = false
            thunkish
          else
            # :nocov:
            raise "Not sure what to do with a record that isn't loaded, created, or persisted"
            # :nocov:
          end
        end

        def build_method
          if to_type.extends?(BuiltinTypes[:entity])
            # TODO: figure out a way to test this path
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
