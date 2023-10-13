module Foobara
  module Persistence
    class EntityBase
      attr_accessor :tables, :name, :entity_attributes_crud_driver

      class << self
        def using_transactions(existing_transactions, &block)
          if existing_transactions.empty?
            block.call
          elsif existing_transactions.size == 1
            existing_transaction = existing_transactions.first

            existing_transaction.entity_base.using_transaction(existing_transaction, &block)
          else
            existing_transactions.inject(block) do |nested_proc, existing_transaction|
              proc do
                existing_transaction.entity_base.using_transaction(existing_transaction, &nested_proc)
              end
            end.call
          end
        end
      end

      def initialize(name, entity_attributes_crud_driver:)
        self.entity_attributes_crud_driver = entity_attributes_crud_driver
        self.tables = {}
        self.name = name
        # TODO: a smell?
      end

      def register_entity_class(entity_class, table_name: entity_class.full_entity_name)
        table = EntityBase::Table.new(table_name, self)

        register_table(table)
      end

      def register_table(table)
        tables[table.table_name] = table
      end

      def transaction_key
        @transaction_key ||= "foobara:tx:#{name}"
      end

      def current_transaction
        Thread.foobara_var_get(transaction_key)
      end

      def set_current_transaction(transaction)
        Thread.foobara_var_set(transaction_key, transaction)
      end

      VALID_MODES = [:use_existing, :open_nested, :open_new, nil].freeze

      def using_transaction(existing_transaction, &)
        transaction(existing_transaction:, &)
      end

      def transaction(mode = nil, existing_transaction: nil)
        unless VALID_MODES.include?(mode)
          # :nocov:
          raise ArgumentError, "Mode was #{mode} but expected one of #{VALID_MODES}"
          # :nocov:
        end

        old_transaction = current_transaction

        if old_transaction&.closed?
          old_transaction = nil
        end

        if old_transaction&.currently_open?
          if mode == :use_existing || existing_transaction == old_transaction
            if block_given?
              return yield old_transaction
            else
              return old_transaction
            end
          elsif mode != :open_nested && mode != :open_new
            # :nocov:
            raise "Transaction already open. " \
                  "Use mode :use_existing if you want to make use of the existing transaction. " \
                  "Use mode :open_nested if you are actually trying to nest transactions."
            # :nocov:
          end
        end

        unless block_given?
          return existing_transaction || Transaction.new(self)
        end

        begin
          if existing_transaction
            tx = existing_transaction
          else
            tx = Transaction.new(self)
            tx.open!
          end

          set_current_transaction(tx)
          result = yield tx
          tx.commit! if tx.currently_open? && !existing_transaction
          result
        rescue Foobara::Persistence::EntityBase::Transaction::RolledBack # rubocop:disable Lint/SuppressedException
        rescue => e
          tx.rollback!(e) if tx.currently_open?
          raise
        ensure
          set_current_transaction(old_transaction)
        end
      end
    end
  end
end
