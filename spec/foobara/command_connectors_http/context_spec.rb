Foobara::Monorepo.project :command_connectors_http

RSpec.describe Foobara::CommandConnectors::Http::Context do
  let(:context) { described_class.new(path:) }
  let(:path) { "/run/Whatever" }

  describe "#full_command_name" do
    it "returns the full command name" do
      expect(context.full_command_name).to eq("Whatever")
    end
  end
end
