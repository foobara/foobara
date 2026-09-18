RSpec.describe ":big_decimal" do
  let(:type) { Foobara::BuiltinTypes[:big_decimal] }

  describe "#process!" do
    subject { type.process_value!(value) }

    def is_expected_to_be_big_decimal_for(i_or_s)
      expect(subject).to be_a(BigDecimal)
      expect(subject).to eq(BigDecimal(i_or_s))
    end

    context "when ::BigDecimal" do
      let(:value) { BigDecimal(10) }

      it { is_expected.to be(value) }
    end

    context "when ::Integer" do
      let(:value) { 10 }

      it { is_expected_to_be_big_decimal_for(10) }
    end

    context "when '1.3'" do
      let(:value) { "1.3" }

      it { is_expected_to_be_big_decimal_for("1.3") }
    end

    context "when '-1.3E-5'" do
      let(:value) { "-1.3E-5" }

      it { is_expected_to_be_big_decimal_for("-0.000013") }
    end

    context "when not castable" do
      let(:value) { "notcastable" }

      it { is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError) }
    end
  end
end
