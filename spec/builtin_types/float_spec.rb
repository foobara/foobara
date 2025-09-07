RSpec.describe ":float" do
  let(:type) { Foobara::BuiltinTypes[:float] }

  describe "caster names" do
    it "gives the names of the casters including the dynamically generated class matcher" do
      expect(type.value_caster.processor_names).to eq(
        [
          "Foobara::BuiltinTypes::Float::Casters::Integer",
          "Foobara::BuiltinTypes::Float::Casters::String"
        ]
      )
    end
  end

  describe "#needs_cast?" do
    subject { type.needs_cast?(value) }

    context "when Float" do
      let(:value) { 1.3 }

      it { is_expected.to be(false) }
    end

    context "when something else" do
      let(:value) { Object.new }

      it { is_expected.to be(true) }
    end
  end

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
      let(:value) { "notcastable" }

      it { is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError) }
    end
  end
end
