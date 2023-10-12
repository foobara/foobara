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
      end

      foobara_domain!
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
      end

      foobara_organization!
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
          end

          foobara_domain!
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
      describe "#manifest" do
        it "gives a whole manifest of everything" do
          manifest = Foobara.manifest[:SomeOrg][:SomeDomain][:commands][:SomeCommand]
          expect(manifest[:result_type][:element_type_declarations][:bar][:type]).to eq(:integer)

          expect(Foobara.all_organizations).to include(organization)
          expect(Foobara.all_domains).to include(domain)
          expect(Foobara.all_commands).to include(command_class)
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

      model_class.attributes(a: :integer, b: :symbol)
    end

    it "automatically registers it" do
      expect(domain_module.const_get(:SomeNewModel).domain).to eq(domain)
      type = domain_module.type_for_declaration(:SomeNewModel)
      expect(type.full_type_name).to eq("SomeDomain::SomeNewModel")
      expect(Foobara.all_types).to include(type)
    end

    # TODO: this belongs elsewhere"
    describe ".manifest" do
      let(:manifest) { Foobara.manifest }

      it "gives a whole manifest of everything" do
        expect(manifest).to be_a(Hash)
        model_manifest = manifest[:global_organization][:SomeDomain][:types][:SomeNewModel]
        expect(model_manifest[:base_type]).to eq(:model)
        expect(model_manifest[:target_classes]).to eq(["SomeDomain::SomeNewModel"])
      end
    end
  end

  context "when creating a model from a module and an existing class but by name" do
    let(:model_class) { Class.new(Foobara::Model) }

    before do
      domain_module.const_set("SomeNewModel", model_class)
    end

    it "automatically registers it" do
      type = domain_module.type_for_declaration(
        type: :model,
        name: :SomeNewModel,
        model_module: domain_module,
        attributes_declaration: { a: :integer, b: :symbol }
      )
      expect(type.full_type_name).to eq("SomeDomain::SomeNewModel")
      expect(Foobara.all_types).to include(type)
    end
  end
end
