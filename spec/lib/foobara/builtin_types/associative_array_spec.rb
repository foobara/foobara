RSpec.describe ":associative_array" do
  let(:type) { Foobara::BuiltinTypes[:associative_array] }

  describe "#process!" do
    subject { type.process!(value) }

    context "when array of pairs" do
      let(:value) { [[:a, 1], [:b, 2]] }

      it { is_expected.to eq(a: 1, b: 2) }
    end

    context "when hash" do
      let(:value) { { a: 1, b: 2 } }

      it { is_expected.to eq(a: 1, b: 2) }
    end

    context "when not castable" do
      let(:value) { Object.new }

      it {
        is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError, /Expected it to be a Enumerable/)
      }
    end
  end

  describe "#cast!" do
    subject { type.cast!(value) }

    context "when not castable" do
      let(:value) { Object.new }

      it {
        is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError,
                             /Expected it to be a an array of pairs, or be a Hash\z/)
      }
    end
  end
end
