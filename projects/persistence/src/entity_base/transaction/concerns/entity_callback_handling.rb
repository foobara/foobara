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

        # Entity.after_subclass_defined do |entity_class|
        # end

        # TODO: maybe use class-level callbacks to improve performance?
        Entity.after_dirtied do |record:, **|
          binding.pry
        end

        Entity.after_undirtied do |record:, **|
          binding.pry
        end

        Entity.after_hard_deleted do |record:, **|
          binding.pry
        end

        Entity.after_unhard_deleted do |record:, **|
          binding.pry
        end

        Entity.after_initialized_thunk do |record:, **|
          binding.pry
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
      end
    end
  end
end
