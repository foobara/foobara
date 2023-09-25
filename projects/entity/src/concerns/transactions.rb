module Foobara
  class Entity < Model
    module Concerns
      module Transactions
        class CurrentTransactionIsClosed < StandardError; end

        include Concern

        attr_accessor :transaction

        module ClassMethods
          def current_transaction_table
            Foobara::Persistence.current_transaction_table(self)
          end

          def transaction(...)
            entity_base.transaction(...)
          end
        end

        def verify_transaction_is_open!
          if transaction && !transaction.open?
            # :nocov:
            raise CurrentTransactionIsClosed,
                  "Cannot make further updates to this record because the transaction has been closed."
            # :nocov:
          end
        end
      end
    end
  end
end
