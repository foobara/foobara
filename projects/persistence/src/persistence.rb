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
      def transaction(*objects, mode: nil, &block)
        # def transaction(mode = nil, existing_transaction: nil)
        bases = objects_to_bases(objects)

        if bases.empty?
          # :nocov:
          raise "No bases found for #{objects}"
          # :nocov:
        end

        if bases.size == 1
          bases.first.transaction(mode, &block)
        else
          bases.inject(block) do |nested_proc, base|
            proc do
              base.transaction(mode, &nested_proc)
            end
          end.call
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
        if objects.size > 1 && objects.all? { |o| o.is_a?(::Class) && o < Entity }
          objects = EntityBase.order_entity_classes(objects)
        end

        objects.map do |object|
          object_to_base(object)
        end.uniq
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

      def base_for_entity_class_name(entity_class_name)
        table_for_entity_class_name(entity_class_name).entity_base
      end

      def base_for_entity_class(entity_class)
        table_for_entity_class_name(entity_class.full_entity_name).entity_base
      end

      def table_for_entity_class_name(entity_class_name)
        table = tables_for_entity_class_name[entity_class_name]

        return table if table

        if default_base
          table = EntityBase::Table.new(entity_class_name, default_base)
          default_base.register_table(table)
          tables_for_entity_class_name[entity_class_name] = table
        else
          # :nocov:
          raise NoTableOrCrudDriverError,
                "Can't find table for #{entity_class_name} and can't dynamically build one without default crud driver."
          # :nocov:
        end
      end

      def register_base(base)
        # TODO: add some validations here
        bases[base.name] = base
      end

      def register_entity(base, entity_class, table_name: entity_class.full_entity_name)
        base = to_base(base)

        table = base.register_entity_class(entity_class, table_name:)
        tables_for_entity_class_name[entity_class.full_entity_name] = table
      end

      def tables_for_entity_class_name
        @tables_for_entity_class_name ||= {}
      end
    end
  end
end
