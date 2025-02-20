module Foobara
  class Command < Service
    module Concerns
      module Entities
        include Concern

        module ClassMethods
          # Only needed for entities not discoverable through the inputs
          def depends_on_entities(*entities_to_add)
            if entities_to_add.empty?
              @depends_on_entities ||= Set.new
            else
              entities_to_add.each do |entity_class|
                depends_on_entity(entity_class)
              end
            end
          end

          def depends_on_entity(entity_class)
            depends_on_entities << entity_class
          end

          def entity_class_paths
            # TODO: bust this cache when changing inputs_type??
            @entity_class_paths ||= Entity.construct_associations(
              inputs_type
            ).transform_values(&:target_class)
          end

          # TODO: move to better concern!
          # TODO: make work with inheritance
          def to_load(*paths)
            h = @to_load_paths_and_error_classes || {}

            paths.each do |path|
              path = DataPath.new(path)
              entity_class = entity_class_paths[path.to_s]
              error_class = Entity::NotFoundError.subclass(self, entity_class, path)
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

          thunks_to_load = thunks.reject(&:created?)

          begin
            # here... filter out created entities...
            if thunks_to_load.size == 1
              entity_class.load(thunks_to_load.first)
            else
              entity_class.load_many(thunks_to_load)
            end

            thunks_to_load
          rescue Entity::NotFoundError => e
            add_runtime_error(error_class.new(e.criteria))
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
