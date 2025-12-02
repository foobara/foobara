RSpec.describe Foobara::Command do
  after do
    Foobara.reset_alls
  end

  describe "#run_subcommand!" do
    before do
      # TODO: don't really need to eager-load via before like this, use let!
      domain_module1
      domain_module2
      domain_module3
      command_class1
      command_class2
      top_level_command_class
    end

    let(:domain_module1) {
      stub_module "SomeDomain1" do
        foobara_domain!
      end
    }

    let(:domain_module2) {
      stub_module "SomeDomain2" do
        foobara_domain!
      end
    }

    let(:domain_module3) {
      stub_module "SomeDomain3" do
        foobara_domain!
      end
    }

    let(:command_class1) {
      subcommand_class = command_class2

      stub_class command_class1_name, described_class do
        depends_on subcommand_class
        inputs foo: :integer

        define_method :execute do
          run_subcommand!(subcommand_class)
        end
      end
    }

    let(:command_class2) {
      stub_class command_class2_name, described_class do
        def execute
          100 if subcommand?
        end
      end
    }

    let(:top_level_command_class) {
      stub_class "TopLevelCommand", described_class
    }

    let(:command) { command_class1.new }
    let(:outcome) { command.run }
    let(:result) { outcome.result }

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

      # TODO: this belongs elsewhere
      describe ".foobara_manifest" do
        it "contains the depends_on information for the commands" do
          command_manifest = Foobara.manifest[:command][:"SomeDomain1::SomeCommand1"]

          expect(command_manifest[:depends_on]).to eq(["SomeDomain1::SomeCommand2"])
        end
      end
    end

    context "when in different domains with no dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      it "is not allowed to run the subcommand" do
        expect(command_class1.full_command_symbol).to eq(:"some_domain1::some_command1")
        expect {
          outcome
        }.to raise_error(Foobara::CommandPatternImplementation::Concerns::Subcommands::CannotAccessDomain)
      end

      describe "#command_clases" do
        it "has the expected classes" do
          expect(domain_module1.foobara_command_classes).to eq([command_class1])
        end
      end
    end

    context "when in different domains with backwards dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      before do
        domain_module2.foobara_depends_on(domain_module1)
      end

      it "is not allowed to run the subcommand" do
        expect { outcome }.to raise_error(
          Foobara::CommandPatternImplementation::Concerns::Subcommands::CannotAccessDomain
        )
      end
    end

    context "when in different domains with correct dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      before do
        domain_module1.foobara_depends_on(SomeDomain2, SomeDomain3)
      end

      it "is allowed to run the subcommand" do
        expect(outcome).to be_success
        expect(result).to eq(100)
      end

      describe "#depends_on?" do
        context "when checking by string" do
          subject { domain_module1.foobara_can_call_subcommands_from?("SomeDomain2") }

          it { is_expected.to be(true) }
        end
      end

      # TODO: this belongs elsewhere
      describe ".manifest" do
        it "contains the depends_on information for the commands" do
          depends_on = Foobara.manifest[:domain][:SomeDomain1][:depends_on]

          expect(depends_on).to contain_exactly("SomeDomain2", "SomeDomain3")
        end
      end
    end
  end

  describe "#domain" do
    context "when command has a prefix" do
      let(:command_class) do
        stub_module "SomeDomain" do
          foobara_domain!
        end
        stub_module "SomeDomain::SomePrefix" do
          foobara_namespace!
          foobara_autoset_namespace!
          foobara_autoset_scoped_path!
        end
        stub_class "SomeDomain::SomePrefix::SomeCommand", described_class
      end

      it "returns the domain" do
        expect(command_class.domain).to eq(SomeDomain)
      end
    end
  end
end
