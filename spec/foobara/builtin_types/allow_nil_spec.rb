RSpec.describe Foobara::BuiltinTypes::Duck::SupportedCasters::AllowNil do
  let(:type_declaration) do
    :integer
  end

  let(:type) do
    Foobara::GlobalDomain.foobara_type_from_declaration(*Foobara::Util.array(type_declaration))
  end

  describe ".instance" do
    it "has false declaration data" do
      expect(described_class.instance.declaration_data).to be(false)
    end
  end

  context "when not set" do
    it "does not allow nil" do
      outcome = type.process_value(5)
      expect(outcome).to be_success
      expect(outcome.result).to eq(5)

      outcome = type.process_value(nil)
      expect(outcome).to_not be_success
      expect(outcome.error_keys).to eq(["data.cannot_cast"])
    end
  end

  context "when set to true" do
    let(:type_declaration) do
      [:integer, { allow_nil: true }]
    end

    it "does allow nil" do
      outcome = type.process_value(5)
      expect(outcome).to be_success
      expect(outcome.result).to eq(5)

      outcome = type.process_value(nil)
      expect(outcome).to be_success
      expect(outcome.result).to be_nil
    end
  end

  context "with entire attributes that allow_nil" do
    let(:type_declaration) do
      {
        type: :attributes,
        element_type_declarations: {
          foo: :integer
        },
        required: :foo,
        allow_nil: true
      }
    end

    context "when not nil" do
      it "works as usual" do
        outcome = type.process_value(foo: 5)

        expect(outcome).to be_success
        expect(outcome.result).to eq(foo: 5)
      end
    end

    context "when nil" do
      it "returns nil" do
        outcome = type.process_value(nil)

        expect(outcome).to be_success
        expect(outcome.result).to be_nil
      end
    end
  end

  context "with attribute that is allow_nil" do
    let(:type_declaration) do
      proc do
        default :integer
        implicit_true :integer, :allow_nil
        explicit_true :integer, allow_nil: true
        explicit_false :integer, allow_nil: false
      end
    end

    it "allows nil the implicit true and the explicit true" do
      outcome = type.process_value(
        default: nil,
        implicit_true: nil,
        explicit_true: nil,
        explicit_false: nil
      )

      expect(outcome).to_not be_success
      expect(outcome.error_keys).to eq(
        [
          "data.default.cannot_cast",
          "data.explicit_false.cannot_cast"
        ]
      )

      outcome = type.process_value(
        default: 5,
        implicit_true: nil,
        explicit_true: nil,
        explicit_false: 5
      )

      expect(outcome).to be_success
      expect(outcome.result).to eq(
        default: 5,
        implicit_true: nil,
        explicit_true: nil,
        explicit_false: 5
      )
    end

    context "when registering it" do
      before do
        # TODO: we need a helper to simplify this...
        Foobara::Namespace::NamespaceHelpers.foobara_namespace!(type)

        type.type_symbol = :some_type
        type.foobara_parent_namespace ||= Foobara::GlobalDomain
        type.foobara_parent_namespace.foobara_register(type)
      end

      it "shows up in the manifest" do
        manifest = Foobara.manifest

        expect(
          manifest[:type][:some_type][:declaration_data][:element_type_declarations][:implicit_true][:allow_nil]
        ).to be(true)
      end
    end
  end
end
