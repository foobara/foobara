module Foobara
  module CommandConnectors
    class Http < CommandConnector
      def route(request)
        # we should put a foobara request on the env??
        # and a command on the request?
        response = case action
                   when "run"
                     registry_entry = command_registry[command_name]

                     unless registry_entry
                       Response.new(404, {}, "No command found for #{command_name}")
                     end

                     outcome = run_command(registry_entry, request.inputs)
                     outcome_to_response(registry_entry, outcome)
                   when "manifest"
                     get_manifest
                   when "commands"
                     get_commands
                   when "types"
                     get_types
                   when "entities"
                     get_entities
                   end

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

      def outcome_to_response(registry_entry, outcome)
        if outcome.success?
          body = registry_entry.transform_result(outcome.result)
          Request.new(200, {}, body)
        else
          body = registry_entry.transform_errors(outcome.errors)
          Request.new(422, {}, body)
        end
      end

      def run(path:, method:, headers:, query_string:, body:)
        request = self.class::Request.new(command_registry, path:, method:, headers:, query_string:, body:)
        run_request(request)
        request
      end

      def run_request(request)
        request.run
      end
    end
  end
end
