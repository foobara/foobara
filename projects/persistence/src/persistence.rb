module Foobara
  module Persistence
    class NoTableOrCrudDriverError < StandardError; end
    class NoTransactionOpenError < StandardError; end

    class << self
      attr_reader :default_crud_driver

      def default_crud_driver=(crud_driver)
        if default_crud_driver
          # :nocov:
          raise "Default crud driver already set."
          # :nocov:
        end

        @default_crud_driver = crud_driver
      end

      def default_base
        @default_base ||= if default_crud_driver
                            base = EntityBase.new(
                              "default_entity_base",
                              entity_attributes_crud_driver: default_crud_driver
                            )
                            register_base(base)
                          end
      end

      # TODO: automatically order these by dependency...
      # TODO: also, consider automatically opening transactions for dependent entities automatically...
      def transaction(*objects, mode: nil, &)
        bases = objects_to_bases(objects)

        if bases.empty?
          # :nocov:
          raise "No bases found for #{objects}"
          # :nocov:
        end

        if bases.size == 1
          bases.first.transaction(mode, &)
        else
          Foobara::TransactionGroup.run(bases:, mode:, &)
        end
      end

      # TODO: support transactions across multiple bases
      def current_transaction(object)
        base = to_base(object)
        base.current_transaction
      end

      def current_transaction!(object)
        base = to_base(object)
        tx = base.current_transaction

        unless tx
          # :nocov:
          raise NoTransactionOpenError
          # :nocov:
        end

        tx
      end

      def current_transaction_table!(object)
        current_transaction!(object).table_for(object)
      end

      def current_transaction_table(object)
        current_transaction(object).table_for(object)
      end

      def to_base(object)
        bases = to_bases(object)

        if bases.empty?
          # :nocov:
          raise "Could not find a base for #{object}"
          # :nocov:
        end

        if bases.size > 1
          # :nocov:
          raise "Expected to only find 1 base for #{object} but found #{bases.size}"
          # :nocov:
        end

        bases.first
      end

      def to_bases(object)
        objects_to_bases(Util.array(object))
      end

      def objects_to_bases(objects)
        unsorted = objects.map do |object|
          object_to_base(object)
        end.uniq

        if bases_need_sorting?
          sort_bases!
        end

        bases.values & unsorted
      end

      def object_to_base(object)
        case object
        when EntityBase
          object
        when ::String
          bases[object]
        when ::Symbol
          bases[object.to_s]
        when Class
          base_for_entity_class(object)
        when Entity
          base_for_entity_class(object.class)
        else
          # :nocov:
          raise ArgumentError, "Not able to convert #{object} to an entity base"
          # :nocov:
        end
      end

      def bases
        @bases ||= {}
      end

      def base_for_entity_class(entity_class)
        table_for_entity_class(entity_class).entity_base
      end

      def table_for_entity_class(entity_class)
        entity_class_name = entity_class.full_entity_name
        table = tables_for_entity_class_name[entity_class_name]

        return table if table

        domain = entity_class.domain

        base = domain.foobara_default_entity_base || default_base

        if base
          table = EntityBase::Table.new(entity_class_name, base)
          base.register_table(table)
          tables_for_entity_class_name[entity_class_name] = table
        else
          # :nocov:
          raise NoTableOrCrudDriverError,
                "Can't find table for #{entity_class_name} and can't dynamically build one without default crud driver."
          # :nocov:
        end
      end

      def register_base(*args, name: nil, table_prefix: nil)
        base = case args
               in [EntityBase]
                 args.first
               in [Class => crud_driver_class, *rest] if crud_driver_class < EntityAttributesCrudDriver
                 unless name
                   # :nocov:
                   raise ArgumentError, "Must provide name: when registering a base with a crud driver class"
                   # :nocov:
                 end

                 crud_args, opts = case rest
                                   in [Hash]
                                     # TODO: test this code path
                                     # :nocov:
                                     [[], rest]
                                     # :nocov:
                                   in [] | [Array] | [Array, Hash]
                                     rest
                                   end

                 crud_driver = crud_driver_class.new(*crud_args, **opts, table_prefix:)
                 EntityBase.new(name, entity_attributes_crud_driver: crud_driver)
               end

        bases_need_sorting!
        bases[base.name] = base
      end

      def sort_bases(bases)
        return bases.dup if bases.size <= 1

        if bases_need_sorting?
          sort_bases!
        end

        sorted_bases = self.bases.values & bases

        missing = bases - sorted_bases

        unless missing.empty?
          # :nocov:
          raise ArgumentError, "Missing bases: #{missing} are the not registered or something?"
          # :nocov:
          # sorted_bases = [*missing, *sorted_bases]
        end

        sorted_bases
      end

      def sort_transactions(transactions)
        return transactions.dup if transactions.size <= 1

        if bases_need_sorting?
          sort_bases!
        end

        sorted_bases = bases.values & transactions.map(&:entity_base)

        sorted_bases.map do |base|
          transactions.find { |tx| tx.entity_base == base }
        end
      end

      # TODO: make this private
      # TODO: add a callback so objects that are sensitive to this order can update when needed
      def sort_bases!
        return if bases.size <= 1

        old_bases = bases.values

        entity_classes = []

        old_bases.each do |base|
          entity_classes += base.entity_classes
        end

        return if entity_classes.size <= 1

        entity_classes.select!(&:contains_associations?)

        return if entity_classes.size <= 1

        entity_classes = EntityBase.order_entity_classes(entity_classes)

        new_bases = entity_classes.map(&:entity_base)
        new_bases.reverse!
        new_bases.uniq!

        missing = old_bases - new_bases

        unless missing.empty?
          new_bases = [*new_bases, *missing]
        end

        @bases_need_sorting = false

        self.last_table_count = table_count

        @bases = new_bases.to_h do |base|
          [base.name, base]
        end
      end

      def bases_need_sorting!
        @bases_need_sorting = true
      end

      def bases_need_sorting?
        return true if @bases_need_sorting

        @bases_need_sorting = table_count != last_table_count
      end

      def register_entity(base, entity_class, table_name: entity_class.full_entity_name)
        base = to_base(base)

        table = base.register_entity_class(entity_class, table_name:)
        tables_for_entity_class_name[entity_class.full_entity_name] = table
      end

      def tables_for_entity_class_name
        @tables_for_entity_class_name ||= {}
      end

      private

      attr_accessor :last_table_count

      def table_count
        bases.values.map { |v| v.entity_attributes_crud_driver.tables.size }.sum
      end
    end
  end
end
