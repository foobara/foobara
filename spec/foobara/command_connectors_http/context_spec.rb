RSpec.describe Foobara::CommandConnectors::Http::Request do
  let(:context) { described_class.new(path:) }
  let(:path) { "/run/Whatever" }

  describe "#full_command_name" do
    it "returns the full command name" do
      expect(context.full_command_name).to eq("Whatever")
    end
  end

  describe "#url" do
    subject { request.url }

    let(:request) do
      described_class.new(
        scheme: "https",
        host: "example.com",
        port: 8080,
        path: "/foo/bar",
        query_string: "a=1&b=2"
      )
    end

    it { is_expected.to eq("https://example.com:8080/foo/bar?a=1&b=2") }
  end
end
