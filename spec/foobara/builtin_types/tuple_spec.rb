RSpec.describe ":tuple" do
  let(:type) do
    Foobara::TypeDeclarations::TypeBuilder.type_for_declaration(type_declaration)
  end

  let(:outcome) { type.process_value(value) }
  let(:errors) { outcome.errors }
  let(:error) do
    expect(errors.size).to eq(1)
    errors.first
  end
  let(:result) { outcome.result! }

  let(:type_declaration) do
    [:big_decimal, { a: :integer }]
  end

  context "when using array sugar" do
    describe "#declaration_data" do
      it "converts to strict type declaration successfully" do
        expect(type.declaration_data).to eq(
          type: :tuple,
          element_type_declarations: [
            { type: :big_decimal },
            { type: :attributes, element_type_declarations: { a: { type: :integer } } }
          ],
          size: 2
        )
      end
    end

    describe "#possible_errors" do
      it "converts to strict type declaration successfully" do
        expect(type.possible_errors).to eq(
          "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
          "data.incorrect_tuple_size": Foobara::BuiltinTypes::Array::SupportedValidators::Size::IncorrectTupleSizeError,
          "data.0.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
          "data.1.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
          "data.1.unexpected_attributes":
            Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError,
          "data.1.a.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError
        )
      end
    end
  end

  context "when using strict hash" do
    let(:type_declaration) do
      {
        type: :tuple,
        element_type_declarations: [
          { type: :big_decimal },
          { type: :attributes, element_type_declarations: { a: { type: :integer } } }
        ]
      }
    end

    describe "#process_value!" do
      subject { result }

      context "when valid value" do
        let(:value) { ["3", { a: "2" }] }

        it { is_expected.to eq([BigDecimal(3), { a: 2 }]) }
      end

      context "when value has too many elements" do
        let(:value) { ["3", { a: "2" }, :z] }

        it { is_expected_to_raise(Foobara::BuiltinTypes::Array::SupportedValidators::Size::IncorrectTupleSizeError) }
      end

      context "when an element has an error" do
        let(:value) { ["3", { a: "not valid" }] }

        it "has error for that element" do
          expect(error.to_h).to eq(
            key: "data.1.a.cannot_cast",
            path: [1, :a],
            runtime_path: [],
            category: :data,
            is_fatal: true,
            symbol: :cannot_cast,
            message: 'At 1.a: Cannot cast "not valid" to an integer. Expected it to be a Integer, ' \
                     "or be a string of digits optionally with a minus sign in front",
            context: { cast_to: { type: :integer }, value: "not valid" }
          )
        end
      end
    end

    context "when size doesn't match" do
      let(:type_declaration) { super().merge(size: 3) }

      it "explodes" do
        expect { type }.to raise_error(
          Foobara::BuiltinTypes::Tuple::SupportedProcessors::ElementTypeDeclarations::TypeDeclarationExtension::
              ExtendTupleTypeDeclaration::TypeDeclarationValidators::SizeMatches::IncorrectSizeError
        )
      end
    end
  end

  describe "#process_value!" do
    subject { type.process_value!(value) }

    context "when not castable" do
      let(:value) { Object.new }

      it { is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError) }
    end
  end
end
