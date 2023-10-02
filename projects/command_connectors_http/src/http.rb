module Foobara
  module CommandConnectors
    class Http < CommandConnector
      def route(**)
        request = context_to_request(**)

        run_request(request)
      end

      def not_allowed_to_run_reasons(registry_entry, command)
        # TODO: Need to move the command into the load_records state but not close the transaction...
        allowed_rule = registry_entry.allowed_rule

        return nil unless allowed_rule

        unless command.instance_eval(&allowed_rule.block)
          allowed_rule.explanation
        end
      end

      def context_to_request(**context)
        path = context[:path]

        action, full_command_name = path[1..].split("/")

        if action != "run"
          command_name = case action
                         when "manifest"
                           "QueryManifest"
                         when "commands"
                           "QueryCommands"
                         when "types"
                           "QueryTypes"
                         when "entities"
                           "QueryEntities"
                         else
                           raise "Not sure what to do with #{action}"
                         end

          full_command_name = "Foobara::CommandConnector::#{command_name}"
        end

        registry_entry = command_registry[full_command_name]

        unless registry_entry
          raise "Could not find command registered for #{path}"
        end

        self.class::Request.new(registry_entry, **context)
      end
    end
  end
end
