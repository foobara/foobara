Foobara::Monorepo.project :command_connectors_http

RSpec.describe Foobara::CommandConnectors::Commands::Ping do
  let(:command_connector) do
    Foobara::CommandConnectors::Http.new(default_serializers:)
  end

  let(:authenticator) { nil }
  let(:default_serializers) do
    [Foobara::CommandConnectors::ErrorsSerializer, Foobara::CommandConnectors::JsonSerializer]
  end

  let(:response) { command_connector.run(path:) }

  describe "#run_command" do
    let(:path) { "/ping" }

    it "pongs" do
      expect(response.status).to be(200)
      pong = JSON.parse(response.body)
      expect(pong).to match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}$/)
    end
  end
end
