RSpec.describe ":email" do
  let(:type) { Foobara::BuiltinTypes[:email] }

  describe "#process!" do
    subject { type.process_value!(value) }

    context "when valid string" do
      let(:value) { "foo@bar.baz" }

      it { is_expected.to eq("foo@bar.baz") }
    end

    context "when not castable" do
      let(:value) { Object.new }

      it {
        is_expected_to_raise(
          Foobara::Value::Processor::Casting::CannotCastError,
          /Expected it to be a String/
        )
      }
    end

    context "when uppercase" do
      let(:value) { "FooBar@examPLE.com" }

      it { is_expected.to eq("foobar@example.com") }
    end

    context "when too long" do
      let(:value) { "#{"a" * 70}@example.com" }

      it {
        is_expected_to_raise(
          Foobara::BuiltinTypes::Email::Validators::CannotExceed64Characters.error_class,
          # TODO: this is goofy that it doesn't put a space before 64. Eliminate a bunch of this magic.
          "Cannot exceed64 characters"
        )
      }
    end

    # TODO: test the other rules
  end
end
