RSpec.describe Foobara::Domain do
  after do
    Foobara.reset_alls
  end

  let(:domain) { domain_module.foobara_domain }
  let(:organization) { organization_module.foobara_organization }

  let(:domain_module) {
    Module.new do
      class << self
        def name
          "SomeDomain"
        end

        foobara_domain!
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

  let(:organization_module) do
    Module.new do
      class << self
        def name
          "SomeOrg"
        end

        foobara_organization!
      end
    end
  end

  before do
    stub_const(organization_module.name, organization_module)
    stub_const(domain_module.name, domain_module)
    expect(domain).to be_a(described_class)
    stub_const(command_class.name, command_class)
  end

  context "with simple command" do
    describe "#full_domain_name" do
      subject { domain.full_domain_name }

      it { is_expected.to eq("SomeDomain") }
    end

    describe "#full_domain_symbol" do
      subject { domain.full_domain_symbol }

      it { is_expected.to eq(:some_domain) }
    end

    context "with organization" do
      let(:domain_module) {
        Module.new do
          class << self
            def name
              "SomeOrg::SomeDomain"
            end

            foobara_domain!
          end
        end
      }

      let(:command_class) {
        Class.new(Foobara::Command) do
          class << self
            def name
              "SomeOrg::SomeDomain::SomeCommand"
            end
          end

          result({ foo: :string, bar: :integer })
        end
      }

      describe "#full_domain_name" do
        subject { domain.full_domain_name }

        it { is_expected.to eq("SomeOrg::SomeDomain") }
      end

      describe "#full_domain_symbol" do
        subject { domain.full_domain_symbol }

        it { is_expected.to eq(:"some_org::some_domain") }
      end

      # TODO: belongs elsewhere
      describe "#owns_domain?" do
        subject { organization.owns_domain?(domain) }

        it { is_expected.to be(true) }
      end

      # TODO: belongs elsewhere
      describe "#to_h" do
        it "gives a whole manifest of everything" do
          expect(Foobara.to_h).to eq(
            organizations: [{ organization_name: "SomeOrg", domains: ["SomeDomain"] }],
            domains: [{ organization_name: "SomeOrg",
                        domain_name: "SomeDomain",
                        full_domain_name: "SomeOrg::SomeDomain",
                        depends_on: [],
                        commands: ["SomeCommand"],
                        models: [],
                        types: [] }],
            commands: [{ command_name: "SomeCommand",
                         inputs_type: nil,
                         error_types: [],
                         depends_on: [],
                         result_type: {
                           type: :attributes,
                           element_type_declarations: {
                             foo: { type: :string },
                             bar: { type: :integer }
                           }
                         },
                         domain_name: "SomeDomain",
                         organization_name: "SomeOrg",
                         full_command_name: "SomeOrg::SomeDomain::SomeCommand" }]
          )
        end
      end

      describe "#command_classes" do
        subject { domain.command_classes }

        it { is_expected.to eq([command_class]) }
      end
    end
  end

  context "when creating a model in the domain module" do
    let(:model_class) { Class.new(Foobara::Model) }

    before do
      domain_module.const_set("SomeNewModel", model_class)

      model_class.class_eval do
        attributes(a: :integer, b: :symbol)
      end
    end

    it "automatically registers it" do
      expect(domain_module.const_get(:SomeNewModel).domain).to eq(domain)
    end

    describe "#to_h" do
      it "gives a whole manifest of everything" do
        expect(Foobara.to_h).to eq(
          organizations: [],
          domains: [
            {
              organization_name: nil,
              domain_name: "SomeDomain",
              full_domain_name: "SomeDomain",
              depends_on: [],
              commands: ["SomeCommand"],
              models: ["SomeNewModel"],
              types: [
                {
                  declaration_data: {
                    type: :model,
                    name: "SomeNewModel",
                    model_class:, # TODO: fix this...
                    model_base_class: Foobara::Model, # TODO: fix this...
                    attributes_declaration: {
                      type: :attributes,
                      element_type_declarations: { a: { type: :integer },
                                                   b: { type: :symbol } }
                    }
                  },
                  raw_declaration_data: {
                    type: :model,
                    name: "SomeNewModel",
                    model_class: SomeDomain::SomeNewModel,
                    model_base_class: Foobara::Model,
                    attributes_declaration: {
                      type: :attributes,
                      element_type_declarations: { a: { type: :integer },
                                                   b: { type: :symbol } }
                    }
                  },
                  supported_processors: []
                }
              ]
            }
          ],
          commands: [{ command_name: "SomeCommand",
                       inputs_type: nil,
                       error_types: [],
                       depends_on: [],
                       domain_name: "SomeDomain",
                       organization_name: nil,
                       full_command_name: "SomeDomain::SomeCommand" }]
        )
      end
    end
  end
end
