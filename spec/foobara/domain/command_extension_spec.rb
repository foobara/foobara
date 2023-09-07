RSpec.describe Foobara::Domain::CommandExtension do
  after do
    Foobara.reset_alls
  end

  describe "#run_subcommand!" do
    before do
      [domain_module1, domain_module2, domain_module3].each do |domain_module|
        stub_const(domain_module.name, domain_module)
        expect(domain_module.foobara_domain).to be_a(Foobara::Domain)
      end

      [command_class1, command_class2, top_level_command_class].each do |command_class|
        stub_const(command_class.name, command_class)
      end
    end

    let(:domain_module1) {
      Module.new do
        class << self
          def name
            "SomeDomain1"
          end

          foobara_domain!
        end
      end
    }

    let(:domain_module2) {
      Module.new do
        class << self
          def name
            "SomeDomain2"
          end

          foobara_domain!
        end
      end
    }

    let(:domain_module3) {
      Module.new do
        class << self
          def name
            "SomeDomain3"
          end

          foobara_domain!
        end
      end
    }

    let(:command_class1) {
      name = command_class1_name
      subcommand_class = command_class2

      Class.new(Foobara::Command) do
        singleton_class.define_method :name do
          name
        end

        depends_on subcommand_class
        inputs foo: :integer

        define_method :execute do
          run_subcommand!(subcommand_class)
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
          100 if subcommand?
        end
      end
    }

    let(:top_level_command_class) {
      Class.new(Foobara::Command) do
        singleton_class.define_method :name do
          "TopLevelCommand"
        end
      end
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
      describe "#to_h" do
        it "gives a whole manifest of everything" do
          expect(Foobara.to_h).to eq(
            organizations: [],
            domains: [
              {
                organization_name: nil,
                domain_name: "SomeDomain1",
                full_domain_name: "SomeDomain1",
                depends_on: [],
                commands: %w[SomeCommand1 SomeCommand2]
              },
              { organization_name: nil,
                domain_name: "SomeDomain2",
                full_domain_name: "SomeDomain2",
                depends_on: [],
                commands: [] },
              {
                organization_name: nil,
                domain_name: "SomeDomain3",
                full_domain_name: "SomeDomain3",
                depends_on: [],
                commands: []
              }
            ],
            commands: [
              {
                command_name: "SomeCommand2", inputs_type: nil, error_types: [], depends_on: [],
                domain_name: "SomeDomain1", organization_name: nil, full_command_name: "SomeDomain1::SomeCommand2"
              },
              {
                command_name: "SomeCommand1",
                inputs_type: {
                  type: :attributes,
                  element_type_declarations: { foo: { type: :integer } }
                },
                error_types: [
                  {
                    path: [], runtime_path: [], category: :data, symbol: :cannot_cast, key: "data.cannot_cast",
                    context_type_declaration: {
                      type: :attributes,
                      element_type_declarations: {
                        cast_to: { type: :duck }, value: { type: :duck },
                        attribute_name: { type: :symbol }
                      }
                    }
                  },
                  {
                    path: [],
                    runtime_path: [],
                    category: :data,
                    symbol: :unexpected_attributes,
                    key: "data.unexpected_attributes",
                    context_type_declaration: {
                      type: :attributes,
                      element_type_declarations: {
                        unexpected_attributes: {
                          type: :array,
                          element_type_declaration: { type: :symbol }
                        },
                        allowed_attributes: {
                          type: :array,
                          element_type_declaration: { type: :symbol }
                        }
                      }
                    }
                  },
                  {
                    path: [:foo],
                    runtime_path: [],
                    category: :data,
                    symbol: :cannot_cast,
                    key: "data.foo.cannot_cast",
                    context_type_declaration: {
                      type: :attributes,
                      element_type_declarations: {
                        cast_to: { type: :duck },
                        value: { type: :duck },
                        attribute_name: { type: :symbol }
                      }
                    }
                  }
                ],
                depends_on: ["SomeDomain1::SomeCommand2"],
                domain_name: "SomeDomain1",
                organization_name: nil,
                full_command_name: "SomeDomain1::SomeCommand1"
              },
              {
                command_name: "TopLevelCommand",
                inputs_type: nil,
                error_types: [],
                depends_on: [],
                domain_name: nil,
                organization_name: nil,
                full_command_name: "TopLevelCommand"
              }
            ]
          )
        end
      end
    end

    context "when in different domains with no dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      it "is not allowed to run the subcommand" do
        expect { outcome }.to raise_error(described_class::CannotAccessDomain)
      end

      describe "#command_clases" do
        it "has the expected classes" do
          expect(domain_module1.foobara_domain.command_classes).to eq([command_class1])
        end
      end
    end

    context "when in different domains with backwards dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      before do
        domain_module2.depends_on(domain_module1)
      end

      it "is not allowed to run the subcommand" do
        expect { outcome }.to raise_error(described_class::CannotAccessDomain)
      end
    end

    context "when in different domains with correct dependency" do
      let(:command_class1_name) { "SomeDomain1::SomeCommand1" }
      let(:command_class2_name) { "SomeDomain2::SomeCommand2" }

      before do
        domain_module1.depends_on(SomeDomain2, SomeDomain3)
      end

      it "is allowed to run the subcommand" do
        expect(outcome).to be_success
        expect(result).to eq(100)
      end

      describe "#depends_on?" do
        context "when checking by string" do
          subject { domain_module1.foobara_domain.depends_on?("SomeDomain2") }

          it { is_expected.to be(true) }
        end
      end
    end
  end
end
