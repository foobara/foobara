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

  let(:command_class) do
    stub_class("IncrementAge", Foobara::Command) do
      inputs do
        model SomeModel, :required
      end

      result SomeModel

      def execute
        model.age += 1
        model
      end
    end
  end

  it "can be mutated by a command" do
    expect {
      command_class.run(model: model_instance)
    }.to change(model_instance, :age).by(1)
  end
end
