RSpec.describe Foobara::CommandConnector::Request do
  let(:request) do
    described_class.new
  end

  describe "#serializer" do
    before do
      request.serializers = serializers
    end

    context "when there's no serializers" do
      let(:serializers) { nil }

      it "is nil" do
        expect(request.serializer).to be_nil
      end
    end

    context "when there is a serializer" do
      let(:serializers) { [:yaml] }

      it "returns the serializer" do
        expect(request.serializer.process_value!(foo: 1)).to eq("---\n:foo: 1\n")
      end

      context "when serializer is declared as a class" do
        let(:serializers) { [Foobara::CommandConnectors::Serializers::YamlSerializer] }

        it "returns the serializer" do
          expect(request.serializer.process_value!(foo: 1)).to eq("---\n:foo: 1\n")
        end
      end

      context "when serializer is an instance" do
        let(:serializers) { [Foobara::CommandConnectors::Serializers::YamlSerializer.new("some request")] }

        it "returns the serializer" do
          expect(request.serializer.process_value!(foo: 1)).to eq("---\n:foo: 1\n")
        end
      end

      context "when serializer is a proc" do
        let(:serializers) { [proc { "100" }] }

        it "returns the serializer" do
          expect(request.serializer.process_value!(foo: 1)).to eq("100")
        end
      end
    end

    context "when there are multiple serializers" do
      let(:serializers) { [:yaml, :json] }

      it "returns the serializer" do
        expect(request.serializer.processors.size).to eq(2)
      end
    end
  end

  context "with a ran command" do
    let(:command_class) do
      stub_class("SomeCommand", Foobara::Command) do
        inputs a: :integer

        def execute
          a * a
        end
      end
    end

    let(:command) { command_class.new(inputs).tap(&:run) }
    let(:inputs) { { a: 4 } }
    let(:serializers) { [] }

    before do
      request.command = command
      request.serializers = serializers
    end

    describe "#response_body" do
      it "gives the response body" do
        expect(request.error_collection).to be_empty
        expect(request.response_body).to eq(16)
      end

      context "with a serializer" do
        let(:serializers) { [:json] }

        it "gives the response body" do
          expect(request.response_body).to eq("16")
        end
      end
    end
  end
end
