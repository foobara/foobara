module Foobara
  class Command
    module Concerns
      module ErrorSchema
        extend ActiveSupport::Concern

        class_methods do
          attr_accessor :error_context_schema_map

          def possible_input_error(path, symbol, context_schema = nil)
            path = Array.wrap(path)
            error_context_schema_map[:input][path][symbol] = context_schema.presence
          end

          def error_context_schema_map(map = nil, path = nil, schema_to_process = nil)
            if map.nil?
              return @error_context_schema_map if @error_context_schema_map

              inputs_map = {}

              error_context_schema_map(inputs_map, [], input_schema)

              @error_context_schema_map = {
                input: inputs_map,
                runtime: {}
              }
            else
              map[path] = {}

              return if schema_to_process.blank?

              if schema_to_process.declaration_data[:type] == :attributes
                schema_to_process.element_types.each_pair do |attribute_name, attribute_type|
                  attribute_path = [*path, attribute_name]

                  error_context_schema_map(map, attribute_path, attribute_type)
                end
              end
            end
          end

          def possible_error(symbol, context_schema = nil)
            error_context_schema_map[:runtime][symbol] = context_schema.presence
          end
        end
      end
    end
  end
end
