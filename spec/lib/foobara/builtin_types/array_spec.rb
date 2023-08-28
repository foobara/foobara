RSpec.describe ":array" do
  let(:type) { Foobara::BuiltinTypes[:array] }

  describe "#cast!" do
    subject { type.cast!(value) }

    context "when array" do
      let(:value) { [1, 2] }

      it { is_expected.to eq([1, 2]) }
    end

    context "when hash" do
      let(:value) { { a: 1, b: 2 } }

      it { is_expected.to eq([[:a, 1], [:b, 2]]) }
    end

    context "when not castable" do
      let(:value) { Object.new  }

      it {
        is_expected_to_raise(
          Foobara::Value::Processor::Casting::CannotCastError,
          /Expected it to respond to :to_a/
        )
      }
    end
  end
end
