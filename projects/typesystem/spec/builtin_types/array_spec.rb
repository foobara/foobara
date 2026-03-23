RSpec.describe ":array" do
  let(:type) { Foobara::BuiltinTypes[:array] }

  it "is a builtin type" do
    expect(Foobara::BuiltinTypes.builtin?(type)).to be(true)
  end

  it "is a builtin reference" do
    expect(Foobara::BuiltinTypes.builtin_reference?("array")).to be(true)
  end

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
    let(:type) { Foobara::Domain.current.foobara_type_from_declaration([:integer]) }

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
            message: "At 2: Cannot cast {not: :valid} to an integer. Expected it to be a Integer, " \
                     "or be a string of digits optionally with a minus sign in front",
            context: { cast_to: :integer, value: { not: :valid } }
          }
        )

        expect(type.possible_errors.to_h { |p| [p.key.to_sym, p.error_class] }).to eq(
          "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
          "data.#.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError
        )
      end
    end
  end

  context "when using a type declaration" do
    let(:type) do
      Foobara::Domain.current.foobara_type_from_declaration(type_declaration)
    end

    context "when array type without element_type_declaration" do
      let(:type_declaration) do
        { type: :array }
      end

      it "resolves element_type to nil" do
        # Tests the else branch when element_type_declaration is nil
        expect(type.element_type).to be_nil
      end
    end

    context "when extending with an array literal and a description" do
      let(:type_declaration) do
        { type: [:string], description: "An array of strings", sensitive: true, sensitive_exposed: true }
      end

      it "has the description and is an array type as expected" do
        expect(type.extends?(:array)).to be(true)
        expect(type.description).to eq("An array of strings")
        expect(type).to be_sensitive
        expect(type).to be_sensitive_exposed
        expect(type.process_value!([:foo, 1])).to eq(["foo", "1"])
      end
    end

    context "when element type declaration is a Type" do
      let(:type_declaration) do
        { type: :array, element_type_declaration: Foobara::BuiltinTypes[:integer] }
      end

      it "creates the expected type" do
        s = type.process_value!(["1", "2"])
        expect(s).to eq([1, 2])

        outcome = type.process_value(["asdf"])
        expect(outcome).to_not be_success
      end
    end

    context "when using array sugar of a Type" do
      let(:type_declaration) do
        [Foobara::BuiltinTypes[:integer]]
      end

      it "creates the expected type" do
        s = type.process_value!(["1", "2"])
        expect(s).to eq([1, 2])

        outcome = type.process_value(["asdf"])
        expect(outcome).to_not be_success
      end
    end
  end
end
