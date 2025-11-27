require "foobara/persistence"

module Foobara
  module NestedTransactionable
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
        entity_classes = relevant_entity_classes_for_type(type)

        if entity_classes.empty?
          return yield
        end

        TransactionGroup.run(entity_classes:, &)
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
      Persistence.sort_transactions(@opened_transactions)
    end

    def auto_detect_current_transactions
      bases = nil

      if respond_to?(:relevant_entity_bases)
        bases = relevant_entity_bases

        unless bases.nil?
          return if bases.empty?
        end
      end

      unless bases
        classes = relevant_entity_classes
        return if classes.nil? || classes.empty?

        bases = classes.map(&:entity_base).uniq
      end

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

      bases_needing_transaction = nil

      if respond_to?(:relevant_entity_bases)
        bases_needing_transaction = relevant_entity_bases

        unless bases_needing_transaction.nil?
          return if bases_needing_transaction.empty?
        end
      end

      unless bases_needing_transaction
        classes = relevant_entity_classes
        return if classes.nil? || classes.empty?

        bases_needing_transaction = relevant_entity_classes.map(&:entity_base).uniq - bases_not_needing_transaction
      end

      bases_needing_transaction = Persistence.sort_bases(bases_needing_transaction)

      bases_needing_transaction.each do |entity_base|
        transaction_mode = if respond_to?(:transaction_mode)
                             self.transaction_mode
                           end
        transaction = entity_base.transaction(transaction_mode)
        unless transaction.currently_open?
          transaction.open!
          @opened_transactions ||= []
          @opened_transactions << transaction
        end
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

  class TransactionGroup
    include NestedTransactionable

    class << self
      def run(mode: nil, entity_classes: nil, bases: nil, &)
        new(
          transaction_mode: mode,
          relevant_entity_classes: entity_classes,
          relevant_entity_bases: bases
        ).run(&)
      end
    end

    attr_accessor :relevant_entity_classes, :relevant_entity_bases, :transaction_mode

    def initialize(transaction_mode: nil, relevant_entity_classes: nil, relevant_entity_bases: nil)
      self.relevant_entity_classes = relevant_entity_classes
      self.relevant_entity_bases = relevant_entity_bases
      self.transaction_mode = transaction_mode
    end

    def run(&)
      open_transaction
      result = Persistence::EntityBase.using_transactions(transactions, &)
      commit_transaction
      result
    rescue
      rollback_transaction
      raise
    end
  end
end
