RSpec.describe Foobara::Domain do
  before do
    described_class.reset_unprocessed_command_classes
    described_class.reset_all
  end

  context "with simple command" do
    let(:domain_class) {
      Class.new(described_class) do
        class << self
          def name
            "SomeDomain"
          end
        end
      end
    }

    let(:command_class) {
      Class.new(Foobara::Command) do
        class << self
          def name
            "SomeDomain::SomeCommand"
          end
        end
      end
    }

    before do
      stub_const(domain_class.name, domain_class)
      expect(domain_class.instance).to be_a(domain_class)
      stub_const(command_class.name, command_class)
    end

    describe ".instance.command_classes" do
      it "contains the command" do
        expect(domain_class.instance.command_classes).to eq([command_class])
      end
    end
  end
end
