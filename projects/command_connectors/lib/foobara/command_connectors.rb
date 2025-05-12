# TODO: get this into its own project or at least move it to http
require "cgi"
# TODO: get this out of here and into its own project or at least move it to http
require "json"

module Foobara
  module CommandConnectors
    foobara_domain!

    class << self
      def install!
        CommandConnector.add_desugarizer(CommandConnector::Desugarizers::SymbolsToTrue)
        CommandConnector.add_desugarizer(
          CommandConnector::Desugarizers.rename(:allow_if, :allowed_rule)
        )
        CommandConnector.add_desugarizer(
          CommandConnector::Desugarizers.rename(:inputs, :inputs_transformers)
        )
        CommandConnector.add_desugarizer(
          CommandConnector::Desugarizers.rename(:result, :result_transformers)
        )
        CommandConnector.add_desugarizer(
          CommandConnector::Desugarizers.rename(:request, :request_mutators)
        )
        CommandConnector.add_desugarizer(
          CommandConnector::Desugarizers.rename(:response, :response_mutators)
        )
      end

      def reset_all
        remove_instance_variable("@desugarizer") if defined?(@desugarizer)
        remove_instance_variable("@desugarizers") if defined?(@desugarizers)
      end
    end
  end

  Monorepo.project "command_connectors"
end
