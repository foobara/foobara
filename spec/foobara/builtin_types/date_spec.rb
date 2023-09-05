RSpec.describe ":date" do
  let(:type) { Foobara::BuiltinTypes[:date] }

  describe "#process!" do
    subject { type.process_value!(value) }

    context "when ::Date" do
      let(:value) { Date.new(2020, 1, 2) }

      it { is_expected.to be(value) }
    end

    context "when ::Hash" do
      let(:value) { { year: 2020, month: 1, day: 2 } }

      it { is_expected.to eq(Date.new(2020, 1, 2)) }
    end

    context "when '20200102'" do
      let(:value) { "20200102" }

      it { is_expected.to eq(Date.new(2020, 1, 2)) }
    end

    context "when '2020-01-2'" do
      let(:value) { "2020-01-2" }

      it { is_expected.to eq(Date.new(2020, 1, 2)) }
    end

    context "when not castable" do
      let(:value) { "notcastable" }

      it { is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError) }
    end
  end
end
