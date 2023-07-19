RSpec.describe Foobara::Domain::CommandExtension do
  describe "#run_subcommand!" do
    let(:domain_class1) {
      Class.new(Foobara::Domain) do
        class << self
          def name
            "SomeDomain1"
          end
        end
      end
    }

    let(:command_class1) {
      name = command_class1_name
      sub_command_class = command_class2

      Class.new(Foobara::Command) do
        depends_on sub_command_class

        singleton_class.define_method :name do
          name
        end

        define_method :execute do
          run_subcommand!(sub_command_class)
        end
      end
    }

    let(:domain_class2) {
      Class.new(Foobara::Domain) do
        class << self
          def name
            "SomeDomain2"
          end
        end
      end
    }

    let(:command_class2) {
      name = command_class2_name
      Class.new(Foobara::Command) do
        singleton_class.define_method :name do
          name
        end

        def execute
          100
        end
      end
    }

    let(:command) { command_class1.new }
    let(:outcome) { command.run }
    let(:result) { outcome.result }

    before do
      [domain_class1, domain_class2].each do |domain_class|
        stub_const(domain_class.name, domain_class)
        expect(domain_class.instance).to be_a(domain_class)
      end

      [command_class1, command_class2].each do |command_class|
        stub_const(command_class.name, command_class)
      end
    end

    context "when neither is in a domain" do
      let(:command_class1_name) { "SomeCommand1" }
      let(:command_class2_name) { "SomeCommand2" }

      it "is allowed to run the subcommand" do
        expect(outcome).to be_success
        expect(result).to eq(100)
      end
    end

    context "when command is in domain but sub command is not" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeCommand2" }

      it "is allowed to run the subcommand" do
        expect(outcome).to be_success
        expect(result).to eq(100)
      end
    end

    context "when command is not in a domain but sub command is" do
      let(:command_class1_name) { "SomeCommand1" }
      let(:command_class2_name) { "SomeDomain1::SomeCommand2" }

      it "is allowed to run the subcommand" do
        expect(outcome).to be_success
        expect(result).to eq(100)
      end
    end

    context "when both are in same domain" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain1::SomeCommand2" }

      it "is allowed to run the subcommand" do
        expect(outcome).to be_success
        expect(result).to eq(100)
      end
    end

    context "when in different domains with no dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      it "is not allowed to run the subcommand" do
        expect { outcome }.to raise_error(described_class::CannotAccessDomain)
      end
    end

    context "when in different domains with backwards dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      before do
        domain_class2.depends_on(domain_class1)
      end

      it "is not allowed to run the subcommand" do
        expect { outcome }.to raise_error(described_class::CannotAccessDomain)
      end
    end

    context "when in different domains with correct dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      before do
        domain_class1.depends_on(domain_class2)
      end

      it "is allowed to run the subcommand" do
        expect(outcome).to be_success
        expect(result).to eq(100)
      end
    end
  end
end
