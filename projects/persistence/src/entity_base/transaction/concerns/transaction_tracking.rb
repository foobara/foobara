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
                tx = Persistence.current_transaction(record)

                if tx&.tracking?(record)
                  return tx
                else
                  entity_base = record.class.entity_base

                  tx = open_transactions.find do |transaction|
                    transaction.entity_base == entity_base && transaction.tracking?(record)
                  end
                end

                tx
              end
            end
          end
        end
      end
    end
  end
end
