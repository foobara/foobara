# TODO: get this into its own project or at least move it to http
require "cgi"
# TODO: get this out of here and into its own project or at least move it to http
require "json"

module Foobara
  module CommandConnectors
    foobara_domain!

    class << self
      def install!
        CommandConnector.add_desugarizer Desugarizers::SymbolsToTrue
        CommandConnector.add_desugarizer Desugarizers.rename :allow_if, :allowed_rule
        CommandConnector.add_desugarizer Desugarizers.rename :inputs, :inputs_transformers
        CommandConnector.add_desugarizer Desugarizers.rename :result, :result_transformers
        CommandConnector.add_desugarizer Desugarizers.rename :request, :request_mutators
        CommandConnector.add_desugarizer Desugarizers.rename :response, :response_mutators
        CommandConnector.add_desugarizer Desugarizers::Attributes::OnlyInputs
        CommandConnector.add_desugarizer Desugarizers::Attributes::RejectInputs
        CommandConnector.add_desugarizer Desugarizers::Attributes::OnlyResult
        CommandConnector.add_desugarizer Desugarizers::Attributes::RejectResult
        CommandConnector.add_desugarizer Desugarizers::Attributes::InputsFromYaml
        CommandConnector.add_desugarizer Desugarizers::Auth
      end

      def reset_all
        remove_instance_variable("@desugarizer") if defined?(@desugarizer)
        remove_instance_variable("@desugarizers") if defined?(@desugarizers)
      end
    end
  end

  project "command_connectors"
end
