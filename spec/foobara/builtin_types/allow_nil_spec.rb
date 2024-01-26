RSpec.describe Foobara::BuiltinTypes::Duck::SupportedCasters::AllowNil do
  let(:type_declaration) do
    :integer
  end

  let(:type) do
    Foobara::GlobalDomain.foobara_type_from_declaration(*type_declaration)
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

  context "attribute that is allow_nil" do
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
      binding.pry
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
  end
end
