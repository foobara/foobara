module Foobara
  class Command
    module Concerns
      module Entities
        include Concern

        module ClassMethods
          def entity_class_paths
            # TODO: bust this cache when changing inputs_type??
            @entity_class_paths ||= Entity.construct_associations(
              inputs_type,
              type_namespace: namespace
            ).transform_values(&:target_class)
          end

          # TODO: move to better concern!
          # TODO: make work with inheritance
          def to_load(*paths)
            h = @to_load_paths_and_error_classes || {}

            paths.each do |path|
              path = DataPath.new(path)
              entity_class = entity_class_paths[path.to_s]
              error_class = NotFoundError.subclass(self, entity_class, path)
              h[path.to_s] = error_class
              possible_error(error_class)
            end

            @to_load_paths_and_error_classes = h.sort_by do |path, _error_class|
              [DataPath.new(path).path.size, path]
            end.to_h
          end

          def load_all
            to_load(*entity_class_paths.keys)
          end

          def to_load_paths_and_error_classes
            @to_load_paths_and_error_classes
          end
        end

        def load_entities(data_path)
          error_class = self.class.to_load_paths_and_error_classes[data_path.to_s]
          entity_class = error_class.entity_class

          thunks = DataPath.values_at(data_path, inputs)

          begin
            if thunks.size == 1
              entity_class.load(thunks.first)
            else
              entity_class.load_many(thunks)
            end
          rescue Foobara::Persistence::EntityAttributesCrudDriver::Table::CannotFindError => e
            add_runtime_error(error_class.new(e.record_id))
          end
        end

        # TODO: make this work with collections...
        def load_records
          self.class.to_load.each_key do |data_path|
            load_entities(data_path)
          end
        end
      end
    end
  end
end
