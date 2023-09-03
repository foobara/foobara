RSpec.describe ":boolean" do
  let(:type) { Foobara::BuiltinTypes[:boolean] }

  describe "#process!" do
    subject { type.process_value!(value) }

    context "when true" do
      let(:value) { true }

      it { is_expected.to be(value) }
    end

    context "when false" do
      let(:value) { false }

      it { is_expected.to be(value) }
    end

    context "when 'T'" do
      let(:value) { "T" }

      it { is_expected.to be(true) }
    end

    context "when 0" do
      let(:value) { 0 }

      it { is_expected.to be(false) }
    end

    context "when 'n'" do
      let(:value) { "n" }

      it { is_expected.to be(false) }
    end

    context "when not castable" do
      let(:value) { "fal" }

      it { is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError) }
    end
  end
end
