RSpec.describe Foobara::Model do
  after do
    Foobara.reset_alls
    [
      :SomeModel,
      :SomeEntity,
      :Foo
    ].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
  end

  let(:model_class) do
    stub_class("SomeModel", described_class) do
      attributes do
        name :string, :required
        age :integer, :required
      end
    end
  end
  let(:model_instance) { model_class.new(name:, age:) }
  let(:name) { "foo" }
  let(:age) { 100 }

  it "can be mutated" do
    expect {
      model_instance.age += 1
    }.to change(model_instance, :age).by(1)
  end

  describe "ignore unexpected attributes option" do
    let(:outer_model_class) do
      inner = model_class

      stub_class("OuterModel", described_class) do
        attributes do
          inner_model inner, :required
        end
      end
    end

    it "ignores unexpected attributes" do
      attributes = { inner_model: { age: 100, name: "foo", height: 100 } }

      value = outer_model_class.new(attributes)
      expect(value).to_not be_valid

      value = outer_model_class.new(attributes, ignore_unexpected_attributes: true)
      expect(value).to be_valid

      expect(value.inner_model.attributes.keys).to contain_exactly(:age, :name)
    end
  end

  describe ".deanonymize_class" do
    let(:type_declaration) do
      {
        type: :model,
        name: model_name,
        attributes_declaration:,
        model_module:
      }
    end
    let(:model_name) { "SomeEntity" }
    let(:model_module) { nil }
    let(:attributes_declaration) do
      {
        foo: { type: :integer, max: 10 },
        pk: { type: :integer },
        bar: { type: :string, required: true }
      }
    end
    let(:model_type) do
      Foobara::Domain.current.foobara_type_from_declaration(type_declaration)
    end
    let(:model_class) do
      model_type.target_class
    end

    it "deanonymizes the class" do
      expect(model_class).to be_a(Class)
      expect(model_class.superclass).to be(described_class)
      expect(model_class.name).to be_nil

      described_class.deanonymize_class(model_class)

      expect(model_class.name).to eq(model_name)

      # allowed to call it twice...
      expect(described_class.deanonymize_class(model_class)).to be(model_class)
    end

    context "with a model module that doesn't exist" do
      let(:model_module) { "Foo::Bar::Baz" }

      it "deanonymizes the class" do
        expect(model_class).to be_a(Class)
        expect(model_class.superclass).to be(described_class)
        expect(model_class.name).to be_nil

        described_class.deanonymize_class(model_class)

        expect(model_class.name).to eq("Foo::Bar::Baz::SomeEntity")
      end
    end

    context "when a module already exists with the desired model name" do
      let(:model_module) { "Foo::Bar" }
      let(:model_name) { "SomeModel" }

      before do
        Foobara::Util.make_module_p("Foo::Bar::SomeModel", tag: true)

        stub_const("Foo::Bar::SomeModel::SOME_CONST", "some_const")
      end

      after do
        if Object.const_defined?(:Foo)
          Object.send(:remove_const, :Foo)
        end
      end

      it "upgrades the module to a class and copies over the constants" do
        expect(Foo::Bar::SomeModel).to be_a(Module)
        expect(Foo::Bar::SomeModel).to_not be_a(Class)

        described_class.deanonymize_class(model_class)

        expect(Foo::Bar::SomeModel).to be_a(Class)
        expect(Foo::Bar::SomeModel::SOME_CONST).to eq("some_const")
      end
    end
  end
end
