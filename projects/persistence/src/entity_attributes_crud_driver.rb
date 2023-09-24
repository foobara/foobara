module Foobara
  module Persistence
    class EntityAttributesCrudDriver
      attr_accessor :raw_connection, :tables

      def initialize(connection_or_credentials = nil)
        self.raw_connection = open_connection(connection_or_credentials)
        self.tables = {}
      end

      # TDOO: audit that this interface is correct
      def open_connection(_connection_or_credentials)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def open_transaction
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def flush_transaction(_raw_tx)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def revert_transaction(_raw_tx)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def rollback_transaction(_raw_tx)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def close_transaction(_raw_tx)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def table_for(entity_class)
        key = entity_class.full_entity_name

        tables[key] ||= self.class::Table.new(entity_class, raw_connection)
      end

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

        attr_accessor :table_name, :entity_class, :raw_connection

        def initialize(entity_class, raw_connection, table_name = Util.underscore(entity_class.entity_name))
          self.entity_class = entity_class
          # what is this used for?
          self.raw_connection = raw_connection
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

        def find_by(attributes)
          casted_attributes = entity_class.attributes_type.process_value!(attributes)

          all.each do |found_attributes|
            if casted_attributes.all? { |attribute_name, value| found_attributes[attribute_name] == value }
              return found_attributes
            end
          end
        end

        def find_many_by(attributes)
          casted_attributes = entity_class.attributes_type.process_value!(attributes)

          Enumerator.new do |yielder|
            all.each do |found_attributes|
              if casted_attributes.all? { |attribute_name, value| found_attributes[attribute_name] == value }
                yielder << found_attributes
              end
            end
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
