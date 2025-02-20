module Foobara
  class Command < Service
    module Concerns
      module Transactions
        include Concern

        def transactions
          @transactions ||= []
        end

        def opened_transactions
          @opened_transactions ||= []
        end

        def auto_detect_current_transactions
          bases = relevant_entity_classes.map(&:entity_base).uniq

          bases.each do |base|
            tx = base.current_transaction
            transactions << tx if tx
          end
        end

        def relevant_entity_classes
          @relevant_entity_classes ||= begin
            entity_classes = if inputs_type
                               Entity.construct_associations(
                                 inputs_type
                               ).values.uniq.map(&:target_class)
                             else
                               []
                             end

            if result_type
              entity_classes += Entity.construct_associations(
                result_type
              ).values.uniq.map(&:target_class)
            end

            entity_classes += entity_classes.uniq.map do |entity_class|
              entity_class.deep_associations.values
            end.flatten.uniq.map(&:target_class)

            [*entity_classes, *self.class.depends_on_entities].uniq
          end
        end

        def open_transaction
          auto_detect_current_transactions

          bases_not_needing_transaction = transactions.map(&:entity_base)

          bases_needing_transaction = relevant_entity_classes.map(&:entity_base).uniq - bases_not_needing_transaction

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
