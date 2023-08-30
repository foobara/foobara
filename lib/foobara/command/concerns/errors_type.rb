module Foobara
  class Command
    module Concerns
      module ErrorsType
        extend ActiveSupport::Concern

        class_methods do
          attr_accessor :error_context_type_map

          def possible_could_not_run_subcommand_error(subcommand_error_class)
            possible_error(subcommand_error_class.symbol, subcommand_error_class)
          end

          def possible_error(*args)
            case args.size
            when 1
              error_class = args.first
              symbol = error_class.symbol
            when 2
              symbol, error_class_or_context_type_declaration = args
              error_class = to_runtime_error_class(symbol, error_class_or_context_type_declaration)
            end

            error_context_type_map[:runtime][symbol] = error_class
          end

          def possible_input_error(path, symbol, error_class_or_context_type_declaration)
            path = Array.wrap(path)
            error_class = to_input_error_class(symbol, error_class_or_context_type_declaration)

            error_context_type_map[:input][path][symbol] = error_class
          end

          def update_input_error_context_type_map
            inputs_map = error_context_type_map[:input] || {}
            error_context_type_map(inputs_map, [], inputs_type)
            error_context_type_map[:input] = inputs_map
          end

          def error_context_type_map(map = nil, path = nil, inputs_type_to_process = nil)
            if map.nil?
              return @error_context_type_map if @error_context_type_map

              @error_context_type_map = {
                input: {},
                runtime: {}
              }
              update_input_error_context_type_map

              @error_context_type_map
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

          def lookup_input_error_class(symbol, path)
            error_context_type_map[:input][path][symbol]
          end

          def lookup_runtime_error_class(symbol)
            error_context_type_map[:runtime][symbol]
          end

          def to_could_not_run_subcommand_error_class(subcommand_class)
            Subcommands::FailedToExecuteSubcommand.subclass(
              symbol: could_not_run_subcommand_symbol_for(subcommand_class),
              # TODO: Figure out how to build a more proper context from subcommand_class.error_context_type_map
              context_type_declaration: :duck
            )
          end

          def could_not_run_subcommand_symbol_for(subcommand_class)
            "could_not_#{subcommand_class.name.demodulize.underscore}".to_sym
          end

          # TODO: should we cache these???
          def to_input_error_class(symbol, error_class_or_context_type_declaration)
            if error_class_or_context_type_declaration.is_a?(::Class) &&
               error_class_or_context_type_declaration <= Foobara::Value::DataError
              error_class_or_context_type_declaration
            else
              Foobara::Value::DataError.subclass(
                symbol:,
                context_type_declaration: error_class_or_context_type_declaration
              )
            end
          end

          def to_runtime_error_class(symbol, error_class_or_context_type_declaration)
            if error_class_or_context_type_declaration.is_a?(::Class) &&
               error_class_or_context_type_declaration <= Foobara::Command::RuntimeCommandError
              error_class_or_context_type_declaration
            else
              Foobara::Command::RuntimeCommandError.subclass(
                symbol:,
                context_type_declaration: error_class_or_context_type_declaration
              )
            end
          end
        end
      end
    end
  end
end
