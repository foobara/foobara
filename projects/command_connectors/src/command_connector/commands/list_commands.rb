module Foobara
  class CommandConnector
    module Commands
      class ListCommands < Command
        inputs do
          request :duck # TODO: have some way to specify by Ruby class...
          verbose :boolean
        end

        result [
          [
            :string,
            {
              type: :string,
              allow_nil: true
            }
          ]
        ]

        def execute
          build_list
          build_result
        end

        attr_accessor :list

        def build_list
          self.list = command_connector.command_registry.all_transformed_command_classes
        end

        def verbose?
          verbose
        end

        def build_result
          if verbose?
            list.map do |command_class|
              [command_class.full_command_name, command_class.description]
            end
          else
            list.map do |command_class|
              [command_class.full_command_name, nil]
            end
          end
        end

        def command_connector
          request.command_connector
        end
      end
    end
  end
end
