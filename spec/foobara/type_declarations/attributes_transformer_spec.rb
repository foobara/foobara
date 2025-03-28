RSpec.describe Foobara::AttributesTransformers do
  let(:from_type_declaration) do
    {
      foo: :string,
      bar: :string,
      baz: :string
    }
  end

  let(:from_value) do
    {
      foo: "foo",
      bar: "bar",
      baz: "baz"
    }
  end

  describe ".only" do
    let(:attributes_transformer_class) { described_class.only(*only) }
    let(:attributes_transformer) { attributes_transformer_class.new(from: from_type_declaration) }
    let(:only) { %i[foo bar] }
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

  describe ".reject" do
    let(:attributes_transformer_class) { described_class.reject(*reject) }
    let(:attributes_transformer) { attributes_transformer_class.new(from: from_type_declaration) }
    let(:reject) { %i[baz] }
    let(:to_value) { attributes_transformer.process_value!(from_value) }

    it "removes attributes that are specified in reject" do
      expect(to_value).to eq(foo: "foo", bar: "bar")
    end

    context "when rejecting multiple attributes" do
      let(:reject) { %i[bar baz] }

      it "removes all specified attributes" do
        expect(to_value).to eq(foo: "foo")
      end
    end

    context "when rejecting all attributes" do
      let(:reject) { %i[foo bar baz] }

      it "returns an empty hash" do
        expect(to_value).to eq({})
      end
    end

    context "when rejecting no attributes" do
      let(:reject) { [] }

      it "is a no-op" do
        expect(to_value).to eq(from_value)
      end
    end
  end
end
