module Foobara
  # Might be best to rename this to CrudDrivers or CrudDriver instead of Persistence?
  module Persistence
    class EntityAttributesCrudDriver
      attr_accessor :raw_connection, :tables

      def initialize(connection_or_credentials = nil)
        self.raw_connection = open_connection(connection_or_credentials)
        self.tables = {}
      end

      # Default behavior is for technologies that don't have a connection concept
      # in a proper sense
      def open_connection(_connection_or_credentials)
        # should we return some kind of Connection object here even if it does nothing interesting?
      end

      # Default behavior is for storage technologies that don't support proper
      # transaction support
      def open_transaction
        # Should we have some kind of fake transaction object that raises errors when used after rolledback/closed?
        Object.new
      end

      def flush_transaction(_raw_tx)
      end

      def revert_transaction(_raw_tx)
      end

      def rollback_transaction(_raw_tx)
      end

      def close_transaction(_raw_tx)
      end

      def table_for(entity_class)
        key = entity_class.full_entity_name

        tables[key] ||= self.class::Table.new(entity_class, self)
      end

      # TODO: relocate this to another file?
      class Table
        class CannotCrudError < StandardError
          attr_accessor :record_id

          def verb
            match = /^Cannot(\w+)Error$/.match(Util.non_full_name(self.class))

            unless match
              # :nocov:
              raise "Bad error name for #{self.class.name}"
              # :nocov:
            end

            Util.underscore(match[1])
          end

          def initialize(record_id, submessage = nil)
            self.record_id = record_id
            message = "Could not #{verb} for id #{record_id.inspect}"

            if submessage
              message = "#{message}: #{submessage}"
            end

            super(message)
          end
        end

        class CannotFindError < CannotCrudError; end
        class CannotInsertError < CannotCrudError; end
        class CannotUpdateError < CannotCrudError; end
        class CannotDeleteError < CannotCrudError; end

        attr_accessor :table_name, :entity_class, :raw_connection, :crud_driver

        def initialize(entity_class, crud_driver, table_name = Util.underscore(entity_class.entity_name))
          self.crud_driver = crud_driver
          self.entity_class = entity_class
          # what is this used for?
          self.raw_connection = crud_driver.raw_connection
          self.table_name = table_name
        end

        # CRUD
        def select(_query_declaration)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def all
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def first
          all.first
        end

        def find(_record_id)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def find!(_record_id)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def find_many!(record_ids)
          record_ids.each.lazy.map do |record_id|
            find!(record_id)
          end
        end

        def find_by_attribute_containing(attribute_name, value)
          all.find do |found_attributes|
            found_attributes[attribute_name]&.include?(value)
          end
        end

        def find_all_by_attribute_any_of(attribute_name, values)
          all.select do |attributes|
            values.include?(attributes[attribute_name])
          end
        end

        def find_all_by_attribute_containing_any_of(attribute_name, values)
          all.select do |attributes|
            attributes[attribute_name]&.any? do |attribute_value|
              values.include?(attribute_value)
            end
          end
        end

        def find_by(attributes_filter)
          all.find do |found_attributes|
            matches_attributes_filter?(found_attributes, attributes_filter)
          end
        end

        def find_many_by(attributes_filter)
          Enumerator.new do |yielder|
            all.each do |found_attributes|
              if matches_attributes_filter?(found_attributes, attributes_filter)
                yielder << found_attributes
              end
            end
          end
        end

        def matches_attributes_filter?(attributes, attributes_filter)
          attributes_filter.all? do |attribute_name_or_path, value|
            value = normalize_attribute_filter_value(value)

            if attribute_name_or_path.is_a?(::Array)
              values = DataPath.values_at(attribute_name_or_path, attributes)

              values.any? do |attribute_value|
                normalize_attribute_filter_value(attribute_value) == value
              end
            else
              attribute_value = attributes[attribute_name_or_path]
              normalize_attribute_filter_value(attribute_value) == value
            end
          end
        end

        def normalize_attribute_filter_value(value)
          case value
          when ::Array
            value.map { |v| normalize_attribute_filter_value(v) }
          when ::Hash
            value.to_h do |k, v|
              [normalize_attribute_filter_value(k), normalize_attribute_filter_value(v)]
            end
          when DetachedEntity
            if value.persisted?
              normalize_attribute_filter_value(value.primary_key)
            else
              value
            end
          when Model
            normalize_attribute_filter_value(value.attributes)
          else
            value
          end
        end

        def insert(_attributes)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def insert_many(attributes_array)
          # TODO: add a test for a driver that doesn't override this and remove these :nocov: comments
          # :nocov:
          attributes_array.each.lazy.map do |attributes|
            insert(attributes)
          end
          # :nocov:
        end

        def update(_record)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def hard_delete(_record_id)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def hard_delete_many(record_ids)
          # TODO: add a test for a driver that doesn't override this and remove these :nocov: comments
          # :nocov:
          record_ids.each.lazy.map do |record_id|
            delete(record_id)
          end
          # :nocov:
        end

        def hard_delete_all!
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def count
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def exists?(record_id)
          !!find(record_id)
        end

        def all_exist?(record_ids)
          record_ids.all? do |record_id|
            exists?(record_id)
          end
        end

        def record_id_for(attributes)
          attributes&.[](primary_key_attribute)
        end

        def primary_key_attribute
          entity_class.primary_key_attribute
        end
      end
    end
  end
end
