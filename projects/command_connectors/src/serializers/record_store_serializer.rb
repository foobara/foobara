require_relative "success_serializer"

module Foobara
  module CommandConnectors
    module Serializers
      class RecordStoreSerializer < SuccessSerializer
        def atomic_serializer
          @atomic_serializer ||= AtomicSerializer.new(declaration_data)
        end

        def serialize(_object)
          store = {}

          declaration_data.command.transactions.each do |tx|
            tx.each_table do |table|
              key = table.entity_class.full_entity_name

              map = store[key] ||= {}

              table.tracked_records.each do |record|
                map[record.primary_key] = atomic_serializer.transform(record)
              end
            end
          end

          store
        end
      end
    end
  end
end
