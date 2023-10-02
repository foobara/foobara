module Foobara
  module CommandConnectors
    class Http < CommandConnector
      def route(**context)
        request = context_to_request(**context)

        action = request.action

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

          request = route(context.merge(path: "/run/Foobara::CommandConnector::#{command_name}"))
        end

        request.run_for_context(**context)

        response || Response.new(404, {}, "No route for #{action}")
      end

      def not_allowed_to_run_reasons(registry_entry, command)
        # TODO: Need to move the command into the load_records state but not close the transaction...
        allowed_rule = registry_entry.allowed_rule

        return nil unless allowed_rule

        unless command.instance_eval(&allowed_rule.block)
          allowed_rule.explanation
        end
      end

      def context_to_request(path:, method:, headers:, query_string:, body:)
        self.class::Request.new(command_registry, path:, method:, headers:, query_string:, body:)
      end
    end
  end
end
