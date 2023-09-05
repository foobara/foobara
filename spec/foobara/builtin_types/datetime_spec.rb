RSpec.describe ":datetime" do
  let(:type) { Foobara::BuiltinTypes[:datetime] }

  describe "#process!" do
    subject { type.process_value!(value) }

    context "when ::Time" do
      let(:value) { Time.new(2020, 1, 2, 3, 4, 5, 6) }

      it { is_expected.to be(value) }
    end

    context "when ::Date" do
      let(:value) { Date.new(2020, 1, 2) }

      it { is_expected.to eq(Time.new(2020, 1, 2)) }
    end

    context "when ::Hash" do
      let(:value) { { year: "2020", month: 1, day: 2, hours: 3, minutes: 4, seconds: 5 } }

      it { is_expected.to eq(Time.new(2020, 1, 2, 3, 4, 5)) }

      context "with milliseconds" do
        let(:value) { { year: "2020", month: 1, day: 2, hours: 3, minutes: 4, seconds: 5, milliseconds: 500 } }

        it { is_expected.to eq(Time.new(2020, 1, 2, 3, 4, 5.5)) }
      end

      context "with zone" do
        let(:value) { { year: "2020", month: 1, day: 2, hours: 3, minutes: 4, seconds: 5, zone: "-0700" } }

        it { is_expected.to eq(Time.new(2020, 1, 2, 3, 4, 5, in: "-0700")) }
      end
    end

    context "when '2020-01-02 03:04:05.500 -1200'" do
      let(:value) { "2020-01-02 03:04:05.500 -1200" }

      it { is_expected.to eq(Time.new(2020, 1, 2, 3, 4, 5.5, in: "-12:00")) }
    end

    context "when not castable" do
      let(:value) { "notcastable" }

      it { is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError) }
    end
  end
end
