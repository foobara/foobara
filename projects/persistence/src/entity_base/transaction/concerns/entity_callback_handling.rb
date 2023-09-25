module Foobara
  module Persistence
    class EntityBase
      class Transaction
        module Concerns
          # NOTE: not really a concern...
          module EntityCallbackHandling
            class << self
              def reset_all
                install!
              end

              def install!
                # TODO: do all this in an install! method and make sure Entity.reset_all clears it.
                Entity.after_dirtied do |record:, **|
                  # TODO: don't store transaction directly on the record
                  Transaction.open_transaction_for(record).updated(record)
                end

                Entity.after_undirtied do |record:, **|
                  # TODO: don't store transaction directly on the record
                  Transaction.open_transaction_for(record).updated(record)
                end

                Entity.after_hard_deleted do |record:, **|
                  # TODO: don't store transaction directly on the record
                  Transaction.open_transaction_for(record).hard_deleted(record)
                end

                Entity.after_unhard_deleted do |record:, **|
                  # TODO: don't store transaction directly on the record
                  Transaction.open_transaction_for(record).unhard_deleted(record)
                end

                Entity.after_initialized do |record:, **|
                  if !record.built? && !record.transaction
                    tx = Foobara::Persistence.current_transaction(record)

                    unless tx
                      # TODO: rename
                      raise Foobara::Entity::NoCurrentTransactionError,
                            "Cannot track #{record.entity_name} because not currently in a transaction."
                    end

                    # TODO: stop this...
                    record.transaction = tx
                  end
                end

                Entity.after_initialized_loaded do |record:, **|
                  # TODO: we need a way to not blow up here in case of non-block form of transaction
                  Persistence.current_transaction(record).track_loaded(record)
                end

                Entity.after_initialized_created do |record:, **|
                  # TODO: we need a way to not blow up here in case of non-block form of transaction
                  Persistence.current_transaction(record).track_created(record)
                end

                Entity.after_initialized_thunk do |record:, **|
                  # TODO: we need a way to not blow up here in case of non-block form of transaction
                  Persistence.current_transaction(record).track_unloaded_thunk(record)
                end
              end
            end
          end
        end
      end
    end
  end
end
