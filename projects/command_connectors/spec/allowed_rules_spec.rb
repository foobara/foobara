RSpec.describe Foobara::CommandConnector do
  after { Foobara.reset_alls }

  let(:authenticator) { -> { :some_user } }

  let(:response) { command_connector.run(full_command_name:, action:, inputs:) }
  let(:parsed_response) { JSON.parse(response.body) }

  let(:action) { "run" }
  let(:full_command_name) { "ComputeExponent" }
  let(:inputs) do
    { base:, exponent: }
  end

  let(:command_class) do
    stub_class(:ComputeExponent, Foobara::Command) do
      inputs do
        exponent :integer, :required
        base :integer, :required
      end

      result :integer

      attr_accessor :exponential

      def execute
        compute

        exponential
      end

      def compute
        self.exponential = 1

        exponent.times do
          self.exponential *= base
        end
      end
    end
  end

  context "when independently setting the allowed rules" do
    let(:command_connector) do
      described_class.new(authenticator:,
                          allow: { command_class => -> { base.even? } })
    end

    before do
      command_connector.connect(command_class)
    end

    context "when allowed rule is met" do
      let(:base) { 2 }
      let(:exponent) { 3 }

      it "runs the command" do
        expect(response.status).to be(0)
        expect(response.error).to be_nil
        expect(response.body).to eq(8)
      end
    end

    context "when allowed rule is not met" do
      let(:base) { 3 }
      let(:exponent) { 3 }

      it "is not authorized" do
        expect(response.status).to be(1)

        errors = response.body

        expect(errors.size).to eq(1)
        expect(errors.first).to be_a(Foobara::CommandConnector::NotAllowedError)
      end
    end
  end
end
