RSpec.describe Foobara::BuiltinTypes::Duck::SupportedValidators::OneOf do
  let(:type_declaration) { [:integer, { one_of: }] }
  let(:one_of) { [1, 3, 5] }

  let(:type) do
    Foobara::GlobalDomain.foobara_type_from_declaration(*Foobara::Util.array(type_declaration))
  end

  context "when valid" do
    it "works as usual" do
      expect(type.process_value!(5)).to be(5)
    end
  end

  context "when allow_nil" do
    let(:type_declaration) { [:integer, :allow_nil, { one_of: }] }

    it "can be nil" do
      expect(type.process_value!(nil)).to be_nil
    end
  end

  context "when not valid" do
    it "is not success" do
      outcome = type.process_value(2)

      expect(outcome).to_not be_success

      expect(outcome.errors_hash).to eq(
        "data.value_not_valid" => {
          key: "data.value_not_valid",
          path: [],
          runtime_path: [],
          category: :data,
          symbol: :value_not_valid,
          message: "2 is not one of [1, 3, 5]",
          context: { value: 2, valid_values: [1, 3, 5] },
          is_fatal: false
        }
      )
    end
  end

  context "when module" do
    let(:type_declaration) { [:string, { one_of: }] }
    let(:one_of) do
      stub_module "SomeEnum" do
        const_set(:FOO, :foo)
        const_set(:BAR, :bar)
        const_set(:BAZ, :baz)
      end
    end

    it "works with expected value" do
      expect(type.process_value!(:foo)).to eq("foo")
    end

    context "when not valid" do
      it "is not success" do
        expect(type.declaration_data[:one_of]).to contain_exactly("foo", "bar", "baz")

        outcome = type.process_value(:not_valid)

        expect(outcome).to_not be_success

        expect(outcome.errors.size).to eq(1)

        expect(outcome.errors_hash["data.value_not_valid"][:context][:valid_values]).to contain_exactly("baz", "foo",
                                                                                                        "bar")
      end
    end
  end
end
