RSpec.describe Foobara::Model do
  after { Foobara.reset_alls }

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

      expect(value.inner_model.attributes.keys).to match_array(%i[age name])
    end
  end
end
