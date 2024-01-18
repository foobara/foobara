RSpec.describe ":array" do
  let(:type) { Foobara::BuiltinTypes[:array] }

  describe "#process_value!" do
    subject { type.process_value!(value) }

    context "when array" do
      let(:value) { [1, 2] }

      it { is_expected.to eq([1, 2]) }
    end

    context "when hash" do
      let(:value) { { a: 1, b: 2 } }

      it { is_expected.to eq([[:a, 1], [:b, 2]]) }
    end

    context "when not castable" do
      let(:value) { Object.new }

      it {
        is_expected_to_raise(
          Foobara::Value::Processor::Casting::CannotCastError,
          /Expected it to be a Array, or respond to :to_a/
        )
      }
    end
  end

  describe "#cast!" do
    subject { type.cast!(value) }

    context "when not castable" do
      let(:value) { Object.new }

      it {
        is_expected_to_raise(
          Foobara::Value::Processor::Casting::CannotCastError, /Expected it to be a Array, or respond to :to_a/
        )
      }
    end
  end

  context "when using an element_type_declaration" do
    let(:type) { Foobara::TypeDeclarations::TypeBuilder.type_for_declaration([:integer]) }

    context "when element types match the element_type_declaration" do
      let(:array) { [1, 2, 3, 4] }

      it "can process it" do
        expect(type.process_value!(array)).to eq(array)
      end
    end

    context "when element types do not match the element_type_declaration" do
      let(:array) { [1, 2, { not: :valid }, 4] }

      it "can process it" do
        outcome = type.process_value(array)
        expect(outcome).to_not be_success

        expect(outcome.errors_hash).to eq(
          "data.2.cannot_cast" => {
            key: "data.2.cannot_cast",
            path: [2],
            runtime_path: [],
            is_fatal: true,
            category: :data,
            symbol: :cannot_cast,
            message: "At 2: Cannot cast {:not=>:valid} to an integer. Expected it to be a Integer, " \
                     "or be a string of digits optionally with a minus sign in front",
            context: { cast_to: { type: :integer }, value: { not: :valid } }
          }
        )

        expect(type.possible_errors).to eq(
          "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
          "data.#.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError
        )
      end
    end
  end
end
