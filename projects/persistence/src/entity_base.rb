require "inheritable_thread_vars"

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

        # returns the entities such that ones on the right are allowed to depend on ones on the left
        def order_entity_classes(entity_classes)
          return entity_classes if entity_classes.size <= 1

          without_associations, with_associations = entity_classes.partition do |entity_class|
            entity_class.associations.empty?
          end

          if with_associations.size > 1
            i = 0
            end_at = with_associations.size - 1

            while i < end_at
              entity_class = with_associations[i]
              associations = entity_class.associations.values.uniq

              changed = false

              j = i + 1

              while j <= end_at
                other = with_associations[j]

                if associations.include?(other.foobara_type)
                  with_associations[j] = entity_class
                  with_associations[i] = other
                  changed = true
                  break
                end

                j += 1
              end

              i += 1 unless changed
            end
          end

          without_associations + with_associations
        end
      end

      def initialize(name, entity_attributes_crud_driver:)
        self.entity_attributes_crud_driver = entity_attributes_crud_driver
        self.tables = {}
        self.name = name
      end

      def register_entity_class(entity_class, table_name: entity_class.full_entity_name)
        table = EntityBase::Table.new(table_name, self)

        register_table(table)
      end

      def register_table(table)
        tables[table.table_name] = table
      end

      def entity_classes
        entity_attributes_crud_driver.tables.values.map(&:entity_class)
      end

      def transaction_key
        @transaction_key ||= "foobara:tx:#{name}"
      end

      def current_transaction
        Thread.inheritable_thread_local_var_get(transaction_key)
      end

      def set_current_transaction(transaction)
        Thread.inheritable_thread_local_var_set(transaction_key, transaction)
      end

      # What types of transaction scenarios are there?
      # 1. If a transaction is already open, use it as a "nested transaction", otherwise, open a new one.
      #    A nested transaction means that "rollback" is the same as "revert" and "commit" is the same as "flush".
      #    For a true
      # 2. If a transaction is already open, raise an error. otherwise, open a new one.
      # 3. Open a new, independent transaction, no matter what.
      # 4. If a transaction is already open, use it, otherwise, open a new one.
      # 5. We are outside of a transaction but have a handle on one. We want to set it as the current transaction.
      #    and do some work in that transaction.
      # Which use cases do we probably need at the moment?
      # 1. If we are running a command calling other commands, we will open transactions when needed but
      #    inherit any already-open transactions. Commands don't commit or flush to the already-open transactions
      #    that they inherit. So this feels like a "use existing" situation or a situation where we don't even
      #    bother calling open_transaction at all.  This is the most important use-case.  It can be helpful to raise
      #    in this situation because it is not expected that there's an existing transaction yet we're opening another.
      # 2. We might have a situation where we are in one transaction but definitely want to open a new one and
      #    commit it ourselves and have its results committed and visible independent of the current transaction.
      #    So this feels like a "open new" situation where we don't want to raise an error if a transaction is
      #    already open.
      VALID_MODES = [
        :use_existing,
        :open_nested,
        :open_new,
        nil
      ].freeze

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

        if old_transaction && !old_transaction.currently_open?
          old_transaction = nil
        end

        open_nested = false

        if old_transaction
          if mode == :use_existing || existing_transaction == old_transaction
            if block_given?
              return yield old_transaction
            else
              return old_transaction
            end
          elsif mode == :open_nested
            open_nested = true
          elsif mode == :open_new
            if existing_transaction
              # :nocov:
              raise ArgumentError, "Cannot use mode :open_new with existing_transaction:"
              # :nocov:
            end
          else
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

            if open_nested
              tx.open_nested!(old_transaction)
            else
              tx.open!
            end
          end

          set_current_transaction(tx)

          result = yield tx

          if tx.currently_open? && !existing_transaction
            tx.commit!
          end

          result
        rescue Foobara::Persistence::EntityBase::Transaction::RolledBack # rubocop:disable Lint/SuppressedException
        rescue => e
          if tx.currently_open?
            tx.rollback!(e)
          end
          raise
        ensure
          set_current_transaction(old_transaction)
        end
      end
    end
  end
end
