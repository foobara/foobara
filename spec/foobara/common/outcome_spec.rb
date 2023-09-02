RSpec.describe Foobara::Common::Outcome do
  around do |example|
    Foobara::TypeDeclarations.with_validate_error_context_disabled do
      example.run
    end
  end

  describe ".raise!" do
    subject { described_class.raise!(errors) }

    context "when errors present" do
      let(:errors) { [Foobara::Error.new(message: "message")] }

      it { is_expected_to_raise(Foobara::Error) }
    end

    context "when no errors" do
      let(:errors) { [] }

      it { is_expected_to_not_raise }
    end
  end

  describe "#raise!" do
    subject { outcome.raise! }

    context "when error present" do
      let(:outcome) { described_class.error(Foobara::Error.new(message: "message")) }

      it { is_expected_to_raise(Foobara::Error) }
    end

    context "when errors present" do
      let(:outcome) do
        described_class.errors(
          Foobara::Error.new(symbol: :error1, message: "message1"),
          Foobara::Error.new(symbol: :error2, message: "message2")
        )
      end

      it { is_expected_to_raise(Foobara::Common::Outcome::UnsuccessfulOutcomeError, /message1, message2/) }
    end

    context "when no errors" do
      let(:outcome) { described_class.success(:foo) }

      it { is_expected_to_not_raise }
    end
  end
end
