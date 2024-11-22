RSpec.describe Foobara::Model do
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
end
