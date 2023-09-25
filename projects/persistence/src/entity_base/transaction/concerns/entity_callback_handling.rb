module Foobara
  module Persistence
    class EntityBase
      class Transaction
        module Concerns
          module EntityCallbackHandling
            module ClassMethods
            end
          end
        end

        Entity.after_dirtied do |record:, **|
          # TODO: don't store transaction directly on the record
          record.transaction.updated(record)
        end

        Entity.after_undirtied do |record:, **|
          # TODO: don't store transaction directly on the record
          record.transaction.updated(record)
        end

        Entity.after_hard_deleted do |record:, **|
          # TODO: don't store transaction directly on the record
          record.transaction.hard_deleted(record)
        end

        Entity.after_unhard_deleted do |record:, **|
          # TODO: don't store transaction directly on the record
          record.transaction.unhard_deleted(record)
        end

        Entity.after_initialized do |record:, **|
          if !record.built? && !record.transaction
            tx = Foobara::Persistence.current_transaction(record)

            unless tx
              # TODO: rename
              raise Foobara::Entity::NoCurrentTransactionError,
                    "Cannot track #{record.entity_name} because not currently in a transaction."
            end

            record.transaction = tx
          end
        end

        Entity.after_initialized_loaded do |record:, **|
          # TODO: don't store transaction directly on the record
          record.transaction.track_loaded(record)
        end

        Entity.after_initialized_created do |record:, **|
          # TODO: don't store transaction directly on the record
          record.transaction.track_created(record)
        end

        Entity.after_initialized_thunk do |record:, **|
          # TODO: don't store transaction directly on the record
          record.transaction.track_unloaded_thunk(record)
        end
      end
    end
  end
end
