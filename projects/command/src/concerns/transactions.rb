module Foobara
  class Command
    module Concerns
      module Transactions
        include Concern

        def transactions
          @transactions ||= []
        end

        def opened_transactions
          @opened_transactions ||= []
        end

        def open_transaction
          return unless inputs_type

          bases_not_needing_transaction = transactions.map(&:entity_base)

          # TODO: create a Entity.construct_deep_associations method
          entity_classes = Entity.construct_associations(
            inputs_type,
            type_namespace: self.class.namespace
          ).values.uniq.map(&:target_class)

          entity_classes = entity_classes.map do |entity_class|
            entity_class.deep_associations.values
          end.flatten.map(&:target_class) + Util.array(self.class.inputs_entity_class)
          bases_needing_transaction = entity_classes.map(&:entity_base).uniq - bases_not_needing_transaction

          bases_needing_transaction.each do |entity_base|
            transaction = entity_base.transaction
            transaction.open!
            opened_transactions << transaction
            transactions << transaction
          end
        end

        def rollback_transaction
          opened_transactions.reverse.each do |transaction|
            if transaction.currently_open?
              # Hard to test this because halting and other exceptions rollback the transactions via
              # block form but to be safe keeping this
              # :nocov:
              transaction.rollback!
              # :nocov:
            end
          end
        end

        def commit_transaction
          opened_transactions.reverse.each(&:commit!)
        end
      end
    end
  end
end
