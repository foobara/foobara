module Foobara
  module Persistence
    class EntityBase
      class Transaction
        class CurrentTransactionIsClosedError < StandardError; end
        class NoCurrentTransactionError < StandardError; end

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
                  transaction = Transaction.open_transaction_for(record)

                  unless transaction
                    raise NoCurrentTransactionError,
                          "Cannot modify #{record} because there's no current transaction"
                  end

                  unless transaction.open?
                    # :nocov:
                    raise CurrentTransactionIsClosedError,
                          "Cannot modify #{record} because current transaction is not open"
                    # :nocov:
                  end

                  transaction.updated(record)
                end

                Entity.after_undirtied do |record:, **|
                  transaction = Transaction.open_transaction_for(record)

                  unless transaction
                    # :nocov:
                    raise NoCurrentTransactionError,
                          "Cannot modify #{record} because there's no current transaction"
                    # :nocov:
                  end

                  unless transaction.open?
                    # :nocov:
                    raise CurrentTransactionIsClosedError,
                          "Cannot modify #{record} because current transaction is not open"
                    # :nocov:
                  end

                  transaction.updated(record)
                end

                Entity.after_hard_deleted do |record:, **|
                  transaction = Transaction.open_transaction_for(record)

                  unless transaction
                    # :nocov:
                    raise NoCurrentTransactionError,
                          "Cannot modify #{record} because there's no current transaction"
                    # :nocov:
                  end

                  unless transaction.open?
                    # :nocov:
                    raise CurrentTransactionIsClosedError,
                          "Cannot modify #{record} because current transaction is not open"
                    # :nocov:
                  end

                  transaction.hard_deleted(record)
                end

                Entity.after_unhard_deleted do |record:, **|
                  transaction = Transaction.open_transaction_for(record)

                  unless transaction
                    # :nocov:
                    raise NoCurrentTransactionError,
                          "Cannot modify #{record} because there's no current transaction"
                    # :nocov:
                  end

                  unless transaction.open?
                    # :nocov:
                    raise CurrentTransactionIsClosedError,
                          "Cannot modify #{record} because current transaction is not open"
                    # :nocov:
                  end

                  transaction.unhard_deleted(record)
                end

                Entity.after_initialized_loaded do |record:, **|
                  transaction = Persistence.current_transaction(record)
                  unless transaction
                    # :nocov:
                    raise NoCurrentTransactionError,
                          "Cannot initialize #{record} because there's no current transaction"
                    # :nocov:
                  end

                  unless transaction.open?
                    # :nocov:
                    raise CurrentTransactionIsClosedError,
                          "Cannot initialize #{record} because current transaction is not open"
                    # :nocov:
                  end
                  # TODO: we need a way to not blow up here in case of non-block form of transaction
                  transaction.track_loaded(record)
                end

                Entity.after_initialized_created do |record:, **|
                  transaction = Persistence.current_transaction(record)
                  unless transaction
                    raise NoCurrentTransactionError,
                          "Cannot initialize #{record} because there's no current transaction"
                  end

                  unless transaction.open?
                    # :nocov:
                    raise CurrentTransactionIsClosedError,
                          "Cannot initialize #{record} because current transaction is not open"
                    # :nocov:
                  end
                  # TODO: we need a way to not blow up here in case of non-block form of transaction
                  transaction.track_created(record)
                end

                Entity.after_initialized_thunk do |record:, **|
                  transaction = Persistence.current_transaction(record)
                  unless transaction
                    # :nocov:
                    raise NoCurrentTransactionError,
                          "Cannot initialize #{record} because there's no current transaction"
                    # :nocov:
                  end

                  unless transaction.open?
                    # :nocov:
                    raise CurrentTransactionIsClosedError,
                          "Cannot initialize #{record} because current transaction is not open"
                    # :nocov:
                  end
                  # TODO: we need a way to not blow up here in case of non-block form of transaction
                  transaction.track_unloaded_thunk(record)
                end
              end
            end
          end
        end
      end
    end
  end
end
