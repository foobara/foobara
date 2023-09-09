RSpec.describe ":model" do
  let(:type) do
    Foobara::TypeDeclarations::Namespace.type_for_declaration(type_declaration)
  end

  let(:type_declaration) do
    {
      type: :model,
      name: model_name,
      attributes_declaration:
    }
  end
  let(:model_name) { "SomeModel" }
  let(:attributes_declaration) do
    {
      foo: :integer,
      # TODO: aren't we supposed to be doing required: false instead??
      bar: { type: :string, required: true }
    }
  end

  let(:constructed_model) { type.target_classes.first }

  it "creates a type that targets a Model subclass" do
    expect(type).to be_a(Foobara::Types::Type)
    expect(constructed_model.name).to eq("SomeModel")

    value = constructed_model.new

    expect(value.model_name).to eq("SomeModel")

    expect(value).to be_a(Foobara::Model)
    expect(value).to_not be_valid

    value.foo = "10"

    expect(value.foo).to be(10)
    expect(value).to_not be_valid

    value.bar = "baz"

    expect(value).to be_valid
    expect(value.validation_errors).to be_empty

    value.foo = "invalid"

    expect(value).to_not be_valid

    expect(value.validation_errors.size).to eq(1)
    expect(value.validation_errors.first.to_h).to eq(
      key: "data.foo.cannot_cast",
      path: [:foo],
      runtime_path: [],
      category: :data,
      symbol: :cannot_cast,
      message: "Cannot cast invalid. Expected it to be a Integer, " \
               "or be a string of digits optionally with a minus sign in front",
      context: { cast_to: { type: :integer }, value: "invalid" }
    )

    value = constructed_model.new(foo: 4, bar: "baz")
    expect(value).to be_valid
  end

  it "sets model_class and model_base_class" do
    expect(type.declaration_data[:model_class]).to be(constructed_model)
    expect(type.declaration_data[:model_base_class]).to be(Foobara::Model)
  end

  context "when instantiating via type declaration instead of class" do
    let(:value) { type.process_value!(value_hash) }
    let(:value_hash) do
      { foo: "10", bar: :baz }
    end

    it "constructs value" do
      expect(value).to be_a(constructed_model)
    end
  end
end
