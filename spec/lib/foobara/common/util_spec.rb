RSpec.describe Foobara::Util do
  describe "#args_and_opts_to_args" do
    subject { described_class.args_and_opts_to_args(args, opts) }

    context "when no args" do
      let(:args) { [] }

      context "when no opts" do
        let(:opts) { nil }

        it { is_expected.to eq([]) }
      end

      context "when opts" do
        let(:opts) { { baz: :baz } }

        it { is_expected.to eq([{  baz: :baz }]) }
      end
    end

    context "when arg is nil" do
      let(:args) { [nil] }

      context "when no opts" do
        let(:opts) { nil }

        it { is_expected.to eq([nil]) }
      end

      context "when opts" do
        let(:opts) { { baz: :baz } }

        it { is_expected_to_raise(ArgumentError) }
      end
    end

    context "when 1 arg" do
      let(:args) { [{ foo: :bar }] }

      context "when no opts" do
        let(:opts) { nil }

        it { is_expected.to eq([{ foo: :bar }]) }
      end

      context "when opts" do
        let(:opts) { { baz: :baz } }

        it { is_expected.to eq([{ foo: :bar, baz: :baz }]) }
      end
    end
  end
end
