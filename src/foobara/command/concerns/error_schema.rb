module Foobara
  class Command
    module Concerns
      module ErrorSchema
        extend ActiveSupport::Concern

        class_methods do
          attr_accessor :error_context_type_map

          def possible_input_error(path, symbol, error_class)
            path = Array.wrap(path)
            error_context_type_map[:input][path][symbol] = error_class
          end

          def error_context_type_map(map = nil, path = nil, inputs_type_to_process = nil)
            if map.nil?
              return @error_context_type_map if @error_context_type_map

              inputs_map = {}

              error_context_type_map(inputs_map, [], inputs_type)

              @error_context_type_map = {
                input: inputs_map,
                runtime: {}
              }
            else
              map[path] = {}

              return if inputs_type_to_process.blank?

              if inputs_type_to_process.declaration_data[:type] == :attributes
                inputs_type_to_process.element_types.each_pair do |attribute_name, attribute_type|
                  attribute_path = [*path, attribute_name]

                  error_context_type_map(map, attribute_path, attribute_type)
                end
              end
            end
          end

          def possible_error(symbol, error_class)
            error_context_type_map[:runtime][symbol] = error_class
          end
        end
      end
    end
  end
end
