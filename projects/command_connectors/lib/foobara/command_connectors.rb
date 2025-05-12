# TODO: get this into its own project or at least move it to http
require "cgi"
# TODO: get this out of here and into its own project or at least move it to http
require "json"

module Foobara
  module CommandConnectors
    foobara_domain!
    class << self
      def install!
        CommandConnector.add_desugarizer(CommandConnector::Desugarizers::AllowIf)
        CommandConnector.add_desugarizer(CommandConnector::Desugarizers::Inputs)
        CommandConnector.add_desugarizer(CommandConnector::Desugarizers::Result)
        CommandConnector.add_desugarizer(CommandConnector::Desugarizers::Request)
        CommandConnector.add_desugarizer(CommandConnector::Desugarizers::Response)
        CommandConnector.add_desugarizer(CommandConnector::Desugarizers::SymbolsToTrue)
      end
    end
  end

  Monorepo.project "command_connectors"
end
