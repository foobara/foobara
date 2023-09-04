RSpec.describe ":float" do
  let(:type) { Foobara::BuiltinTypes[:float] }

  describe "#process!" do
    subject { type.process_value!(value) }

    context "when ::Float" do
      let(:value) { 1.3 }

      it { is_expected.to be(value) }
    end

    context "when ::Integer" do
      let(:value) { 10 }

      it { is_expected.to be(10.to_f) }
    end

    context "when '1.3'" do
      let(:value) { "1.3" }

      it { is_expected.to be(1.3) }
    end

    context "when '-1.3E-5'" do
      let(:value) { "-1.3E-5" }

      it { is_expected.to be(-0.000013) }
    end

    context "when not castable" do
      let(:value) { "fal" }

      it { is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError) }
    end
  end
end
