module Foobara
  module NestedTransactionable
    include Concern

    class << self
      def relevant_entity_classes_for_type(type)
        entity_classes = []
        entity_classes += Entity.construct_associations(type).values.map(&:target_class)

        if type.extends?(BuiltinTypes[:entity])
          entity_classes << type.target_class
        end

        entity_classes.uniq.each do |entity_class|
          entity_classes += entity_class.deep_associations.values.map(&:target_class)
        end

        entity_classes.uniq
      end

      def with_needed_transactions_for_type(type, &)
        relevant_entity_classes = relevant_entity_classes_for_type(type)

        if relevant_entity_classes.empty?
          return yield
        end

        tx_class = Class.new
        tx_class.include NestedTransactionable

        tx_class.define_method(:relevant_entity_classes) do
          relevant_entity_classes
        end

        tx_instance = tx_class.new

        begin
          tx_instance.open_transaction
          result = Persistence::EntityBase.using_transactions(tx_instance.transactions, &)
          tx_instance.commit_transaction
          result
        rescue
          tx_instance.rollback_transaction
          raise
        end
      end
    end

    def relevant_entity_classes_for_type(type)
      NestedTransactionable.relevant_entity_classes_for_type(type)
    end

    def relevant_entity_classes
      # :nocov:
      raise "subclass responsibility"
      # :nocov:
    end

    def transactions
      @transactions ||= []
    end

    def opened_transactions
      @opened_transactions ||= []
    end

    def auto_detect_current_transactions
      classes = relevant_entity_classes
      return if classes.nil? || classes.empty?

      bases = classes.map(&:entity_base).uniq

      bases.each do |base|
        tx = base.current_transaction

        if tx&.open?
          transactions << tx
        end
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

    def commit_transaction_if_open
      opened_transactions.reverse.each do |tx|
        if tx.currently_open?
          tx.commit!
        end
      end
    end

    def use_transaction(&)
      Persistence::EntityBase.using_transactions(transactions, &)
    end
  end
end
