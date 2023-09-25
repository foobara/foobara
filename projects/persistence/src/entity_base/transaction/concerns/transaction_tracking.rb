module Foobara
  module Persistence
    class EntityBase
      class Transaction
        module Concerns
          module TransactionTracking
            include Concern

            module ClassMethods
              def install!
                Transaction::StateMachine.register_transition_callback(:after,
                                                                       transition: :open) do |state_machine:, **|
                  transaction = state_machine.owner
                  Transaction.open_transactions << transaction
                end

                Transaction::StateMachine.register_transition_callback(:after, to: :closed) do |state_machine:, **|
                  transaction = state_machine.owner
                  Transaction.open_transactions.delete(transaction)
                end
              end

              def reset_all
                @open_transactions = nil
              end

              def open_transactions
                @open_transactions ||= Set.new
              end

              def open_transaction_for(record)
                # let's check the current_transaction first since that usually will match
                tx = current_transaction(record)

                if tx&.tracking?(record)
                  tx
                else
                  open_transactions.find do |transaction|
                    transaction.tracking?(record)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
