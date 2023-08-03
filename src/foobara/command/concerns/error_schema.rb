module Foobara
  class Command
    module Concerns
      module ErrorSchema
        extend ActiveSupport::Concern

        class_methods do
          attr_accessor :error_context_schema_map

          def possible_input_error(path, symbol, context_schema = nil)
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

              if schema_to_process.is_a?(Foobara::Model::Schemas::Attributes)
                schema_to_process.schemas.each_pair do |attribute_name, schema|
                  attribute_path = [*path, attribute_name]

                  error_context_schema_map(map, attribute_path, schema)
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
