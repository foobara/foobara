module Foobara
  module Persistence
    module CrudDrivers
      class InMemoryMinimal < EntityAttributesCrudDriver
        class Table < EntityAttributesCrudDriver::Table
          attr_accessor :records

          def initialize(...)
            @last_id = 0
            self.records = {}

            super
          end

          # CRUD
          # TODO: all multiple record methods should return enumerators and code further up should only use
          # the lazy enumerator interface... to encourage that/catch bugs we will return lazy enumerators in these
          # built-in crud drivers
          def all(page_size: nil)
            records.each_value.lazy
          end

          def count
            records.count
          end

          def find(record_id)
            Util.deep_dup(records[record_id])
          end

          def insert(attributes)
            attributes = Util.deep_dup(attributes)

            record_id = record_id_for(attributes)

            if record_id
              if exists?(record_id)
                raise CannotInsertError.new(record_id, "already exists")
              end
            else
              record_id = get_id
              attributes.merge!(primary_key_attribute => record_id)
            end

            records[record_id] = attributes
            find(record_id)
          end

          def update(attributes)
            record_id = record_id_for(attributes)

            unless exists?(record_id)
              # :nocov:
              raise CannotUpdateError.new(record_id, "does not exist")
              # :nocov:
            end

            records[record_id] = Util.deep_dup(attributes)
            find(record_id)
          end

          def hard_delete(record_id)
            unless exists?(record_id)
              # :nocov:
              raise CannotUpdateError.new(record_id, "does not exist")
              # :nocov:
            end

            records.delete(record_id)
          end

          def hard_delete_all
            self.records = {}
          end

          # Schema manipulation

          def rename_column(old_name, new_name)
            old_name = old_name.to_sym
            new_name = new_name.to_sym

            records.each_value do |attributes|
              if attributes.key?(old_name)
                attributes[new_name] = attributes.delete(old_name)
              end
            end
          end

          def add_column(name, type: nil)
            name = name.to_sym
            default_value = nil

            if type
              outcome = type.process_value(default_value)
              default_value = outcome.result if outcome.success?
            end

            records.each_value do |attributes|
              attributes[name] = default_value unless attributes.key?(name)
            end
          end

          def drop_column(name)
            name = name.to_sym

            records.each_value do |attributes|
              attributes.delete(name)
            end
          end

          def column_names
            return [] if records.empty?

            records.values.first.keys
          end

          private

          def get_id
            @last_id += 1
          end
        end
      end
    end
  end
end
