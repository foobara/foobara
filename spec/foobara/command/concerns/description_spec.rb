RSpec.describe Foobara::Command::Concerns::Description do
  describe ".description" do
    let(:command_class) do
      stub_class(:SomeCommand, Foobara::Command)
    end

    it "sets and reads the description" do
      expect {
        command_class.description "foo"
      }.to change(command_class, :description).from(nil).to("foo")
    end
  end
end
