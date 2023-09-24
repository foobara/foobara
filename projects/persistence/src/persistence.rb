module Foobara
  module Persistence
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

      # TODO: support transactions across multiple bases
      def current_transaction(object)
        base = to_base(object)
        base.current_transaction
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
        objects.map do |object|
          object_to_base(object)
        end.uniq
      end

      def object_to_base(object)
        case object
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
          raise "Can't find table for #{entity_class_name} and can't dynamically build one without default crud driver."
          # :nocov:
        end
      end

      def register_base(base)
        # TODO: add some validations here
        bases[base.name] = base
      end

      def tables_for_entity_class_name
        @tables_for_entity_class_name ||= {}
      end
    end
  end
end
