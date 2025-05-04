RSpec.describe Foobara::BuiltinTypes::Attributes do
  let(:type) {
    Foobara::Domain.current.foobara_type_from_declaration(type_declaration)
  }

  context "when value is an attributes array" do
    let(:type_declaration) do
      { foo: :integer, bar: :symbol }
    end

    let(:value_to_process) do
      [["foo", "10"], ["bar", "baz"]]
    end

    it "constructs created value" do
      value = type.process_value!(value_to_process)
      expect(value).to be_a(Hash)
      expect(value[:foo]).to eq(10)
      expect(value[:bar]).to eq(:baz)
    end
  end

  describe "when attributes has its own description and element declaration types do as well" do
    let(:type_declaration) do
      {
        type: :attributes,
        element_type_declarations: {
          foo: { type: :integer, description: "foo desc" },
          bar: { type: :string, description: "bar desc" }
        },
        description: "attributes desc"
      }
    end

    it "has all the expected descriptions on the correct types" do
      expect(type.description).to eq("attributes desc")
      expect(type.element_types[:foo].description).to eq("foo desc")
      expect(type.element_types[:bar].description).to eq("bar desc")
    end
  end

  describe "defaults" do
    context "when defaults is not a hash" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            a: :integer
          },
          defaults: [:b, 1]
        }
      end

      it "applies defaults when expected and casts where expected" do
        expect {
          type
        }.to raise_error(
          described_class::SupportedTransformers::Defaults::TypeDeclarationExtension::ExtendAttributesTypeDeclaration::
              TypeDeclarationValidators::HashWithSymbolicKeys::InvalidDefaultValuesGivenError
        )
      end
    end

    context "when defaults contains invalid attribute names" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            a: :integer
          },
          defaults: {
            b: 1
          }
        }
      end

      it "applies defaults when expected and casts where expected" do
        expect {
          type
        }.to raise_error(
          described_class::SupportedTransformers::Defaults::TypeDeclarationExtension::ExtendAttributesTypeDeclaration::
              TypeDeclarationValidators::ValidAttributeNames::InvalidDefaultValueGivenError
        )
      end
    end

    context "when type_declaration has top-level defaults hash" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            a: :integer,
            b: :integer,
            c: :integer
          },
          defaults: {
            "b" => 1,
            c: "2"
          }
        }
      end

      it "applies defaults when expected and casts where expected" do
        attributes = type.process_value!(a: 100, b: 200, c: "300")
        expect(attributes).to eq(a: 100, b: 200, c: 300)

        attributes = type.process_value!(a: 100, c: "300")
        expect(attributes).to eq(a: 100, b: 1, c: 300)

        attributes = type.process_value!(a: 100)
        expect(attributes).to eq(a: 100, b: 1, c: 2)
      end
    end

    context "when type_declaration is a dsl proc" do
      let(:type_declaration) do
        proc do
          a :integer
          b :integer, default: 1
          c :integer, default: "2"
        end
      end

      it "works just like a hash declaration of the same type" do
        attributes = type.process_value!(a: 100, b: 200, c: "300")
        expect(attributes).to eq(a: 100, b: 200, c: 300)

        attributes = type.process_value!(a: 100, c: "300")
        expect(attributes).to eq(a: 100, b: 1, c: 300)

        attributes = type.process_value!(a: 100)
        expect(attributes).to eq(a: 100, b: 1, c: 2)
      end
    end

    context "when type_declaration specifies defaults on a per-attribute level" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            a: { type: :integer  },
            b: { type: :integer, default: 1 },
            c: { type: :integer, default: "2" }
          }
        }
      end

      it "applies defaults when expected" do
        attributes = type.process_value!(a: 100, b: 200, c: "300")
        expect(attributes).to eq(a: 100, b: 200, c: 300)

        attributes = type.process_value!(a: 100, c: "300")
        expect(attributes).to eq(a: 100, b: 1, c: 300)

        attributes = type.process_value!(a: 100)
        expect(attributes).to eq(a: 100, b: 1, c: 2)
      end
    end

    context "when attribute is present but is nil" do
      subject { type.process_value!(foo: "foo", bar: nil)[:bar] }

      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            foo: { type: :string },
            bar: { type: :string, allow_nil:, default: "baz" }
          }
        }
      end
      let(:allow_nil) { false }

      it { is_expected.to eq("baz") }

      context "when attribute is marked as allow_nil => true" do
        let(:allow_nil) { true }

        it { is_expected.to be_nil }
      end
    end
  end

  describe "required attributes" do
    context "when all strings" do
      let(:type_declaration) do
        {
          "type" => "attributes",
          "element_type_declarations" => {
            "a" => { "type" => "integer" },
            "b" => { "type" => "integer" }
          },
          "required" => ["a"]
        }
      end

      it "still works" do
        expect(type.process_value!(a: 1)).to eq(a: 1)
        expect {
          type.process_value!(b: 1)
        }.to raise_error(
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError
        ) do |e|
          expect(e.context[:attribute_name]).to eq(:a)
        end
      end
    end

    context "when required is not an array of symbols" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            a: :integer,
            b: :integer,
            c: :integer
          },
          required: { a: 1 }
        }
      end

      it "explodes" do
        expect {
          type
        }.to raise_error(
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::TypeDeclarationExtension::
              ExtendAttributesTypeDeclaration::TypeDeclarationValidators::ArrayOfSymbols::
              InvalidRequiredAttributesValuesGivenError
        )
      end
    end

    context "when required contains an invalid attribute name" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            a: :integer,
            b: :integer,
            c: :integer
          },
          required: [:a, :d]
        }
      end

      it "explodes" do
        expect {
          type
        }.to raise_error(
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::TypeDeclarationExtension::
              ExtendAttributesTypeDeclaration::TypeDeclarationValidators::ArrayWithValidAttributeNames::
              InvalidRequiredAttributeNameGivenError,
          /\bd\b/
        )
      end
    end

    context "when type_declaration has top-level required array" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            a: :integer,
            b: :integer,
            c: :integer
          },
          required: [:a, :c]
        }
      end

      it "gives errors when required fields missing" do
        outcome = type.process_value(a: 100, b: 200, c: "300")
        expect(outcome).to be_success

        outcome = type.process_value(a: 100, c: "300")
        expect(outcome).to be_success

        outcome = type.process_value(b: 100, c: "300")
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                [
                                                                                  :a, :missing_required_attribute
                                                                                ]
                                                                              ])

        outcome = type.process_value(b: 100)
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                [
                                                                                  :a, :missing_required_attribute
                                                                                ],
                                                                                [:c,
                                                                                 :missing_required_attribute]
                                                                              ])

        outcome = type.process_value({})
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                [
                                                                                  :a, :missing_required_attribute
                                                                                ],
                                                                                [:c,
                                                                                 :missing_required_attribute]
                                                                              ])
      end
    end

    context "when type_declaration has per-attribute required flag" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            a: { type: :integer, required: true },
            b: { type: :integer, required: false },
            c: { type: :integer, required: true }
          }
        }
      end

      it "gives errors when required fields missing" do
        outcome = type.process_value(a: 100, b: 200, c: "300")
        expect(outcome).to be_success

        outcome = type.process_value(a: 100, c: "300")
        expect(outcome).to be_success

        outcome = type.process_value(b: 100, c: "300")
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                [
                                                                                  :a, :missing_required_attribute
                                                                                ]
                                                                              ])

        outcome = type.process_value(b: 100)
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                [
                                                                                  :a, :missing_required_attribute
                                                                                ],
                                                                                [:c,
                                                                                 :missing_required_attribute]
                                                                              ])

        outcome = type.process_value({})
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                [
                                                                                  :a, :missing_required_attribute
                                                                                ],
                                                                                [:c,
                                                                                 :missing_required_attribute]
                                                                              ])
      end
    end
  end
end
