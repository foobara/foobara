module Foobara
  module Persistence
    class EntityBase
      attr_accessor :tables, :name, :entity_attributes_crud_driver

      def initialize(name, entity_attributes_crud_driver:)
        self.entity_attributes_crud_driver = entity_attributes_crud_driver
        self.tables = {}
        self.name = name
        # TODO: a smell?
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

      def transaction(mode = nil)
        unless VALID_MODES.include?(mode)
          # :nocov:
          raise ArgumentError, "Mode was #{mode} but expected one of #{VALID_MODES}"
        end

        old_transaction = current_transaction

        if old_transaction&.closed?
          old_transaction = nil
        end

        if old_transaction&.currently_open?
          if mode == :use_existing
            if block_given?
              return yield old_transaction
            else
              return old_transaction
            end
          elsif mode != :open_nested && mode != :open_new
            raise "Transaction already open. " \
                  "Use mode :use_existing if you want to make use of the existing transaction. " \
                  "Use mode :open_nested if you are actually trying to nest transactions."
          end
        end

        # TODO: handle nested versus new somehow
        tx = Transaction.new(self)

        return tx unless block_given?

        begin
          tx.open!
          set_current_transaction(tx)
          result = yield tx
          tx.commit! if tx.currently_open?
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
