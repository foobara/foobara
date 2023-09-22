RSpec.describe Foobara::Util do
  describe ".const_get_up_hierarchy" do
    subject { described_class.const_get_up_hierarchy(mod, name) }

    context "when anonymous class" do
      let(:mod) { Class.new(String) }
      let(:name) { :Hash }

      it { is_expected.to be(Hash) }

      context "when bad constant" do
        let(:name) { :NoSuchConstant }

        it { is_expected_to_raise(NameError, "uninitialized constant NoSuchConstant") }
      end
    end
  end

  describe ".underscore" do
    context "when symbol" do
      it "still works" do
        expect(described_class.underscore(:ClassMethods)).to eq("class_methods")
      end
    end
  end

  describe ".args_and_opts_to_opts" do
    subject { described_class.args_and_opts_to_opts(args, opts) }

    context "when args is a hash and so is opts" do
      let(:args) { [{ a: 1, b: 2 }] }
      let(:opts) { { c: 3, d: 4 } }

      it { is_expected.to eq(a: 1, b: 2, c: 3, d: 4) }
    end
  end

  describe ".args_and_opts_to_args" do
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
