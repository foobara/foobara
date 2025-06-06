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

          def get_id
            @last_id += 1
          end

          # CRUD
          # TODO: all multiple record methods should return enumerators and code further up should only use
          # the lazy enumerator interface... to encourage that/catch bugs we will return lazy enumerators in these
          # built-in crud drivers
          def all
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
        end
      end
    end
  end
end
