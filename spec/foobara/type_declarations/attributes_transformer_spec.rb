RSpec.describe Foobara::AttributesTransformer do
  describe ".only" do
    let(:from_type_declaration) do
      {
        foo: :string,
        bar: :string,
        baz: :string
      }
    end

    let(:attributes_transformer_class) { described_class.only(*only) }
    let(:attributes_transformer) { attributes_transformer_class.new(from: from_type_declaration) }
    let(:only) { %i[foo bar] }

    let(:from_value) do
      {
        foo: "foo",
        bar: "bar",
        baz: "baz"
      }
    end

    let(:to_value) { attributes_transformer.process_value!(from_value) }

    it "removes attributes other than what is passed to only" do
      expect(to_value).to eq(foo: "foo", bar: "bar")
    end

    context "when only matches all attributes" do
      let(:only) { %i[foo bar baz] }

      it "is a no-op" do
        expect(to_value).to eq(from_value)
      end
    end
  end
end
