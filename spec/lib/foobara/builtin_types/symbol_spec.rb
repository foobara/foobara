RSpec.describe ":symbol" do
  let(:type) { Foobara::BuiltinTypes[:symbol] }

  describe "#cast!" do
    subject { type.cast!(value) }

    context "when string" do
      let(:value) { "foo" }

      it { is_expected.to be(:foo) }
    end

    context "when not castable" do
      let(:value) { Object.new  }

      it {
        is_expected_to_raise(
          Foobara::Value::Processor::Casting::CannotCastError,
          /Expected it to be a String, or be a Symbol/
        )
      }
    end
  end
end
