RSpec.describe Foobara::CommandConnector::Commands::Ping do
  let(:command_connector) do
    Foobara::CommandConnector.new
  end

  let(:response) { command_connector.run(action: "ping") }

  describe "#run_command" do
    it "pongs" do
      expect(response.status).to be(0)
      expect(response.body).to be_a(Time)
    end
  end
end
