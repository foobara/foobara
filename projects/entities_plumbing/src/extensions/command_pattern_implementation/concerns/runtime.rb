module Foobara
  module CommandPatternImplementation
    module Concerns
      module Runtime
        def validate_records
          self.class.inputs_association_paths&.each do |data_path|
            if data_path.last == :"#"
              records = data_path.values_at(@inputs)

              records.each.with_index do |record, index|
                if record&.persisted? && !record.loaded?
                  begin
                    record.class.load(record)
                  rescue Foobara::Entity::NotFoundError => e
                    e.prepend_path!(index)
                    e.prepend_path!(data_path.path[..-2])

                    add_input_error(e)
                  end
                end
              end
            else
              record = data_path.value_at(@inputs)

              if record&.persisted? && !record.loaded?
                begin
                  record.class.load(record)
                rescue Foobara::Entity::NotFoundError => e
                  e.prepend_path!(data_path)
                  add_input_error(e)
                end
              end
            end
          end
        end
      end
    end
  end
end
