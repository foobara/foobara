RSpec.describe Foobara::Domain do
  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  after do
    Foobara.reset_alls
  end

  let(:domain) { domain_module.foobara_domain }
  let(:organization) { stub_module(:SomeOrg) { foobara_organization! } }
  let(:domain_module) {
    stub_module :SomeDomain do
      foobara_domain!
    end
  }

  let!(:command_class) {
    stub_class "#{domain_module.name}::SomeCommand", Foobara::Command
  }

  describe ".to_domain" do
    context "when nil" do
      it "is the global domain" do
        expect(described_class.to_domain(nil)).to be_global
      end
    end
  end

  describe ".register_entity" do
    let(:entity_name) { :SomeEntity }
    let(:primary_key) { :id }
    let(:attributes_declaration) do
      {
        first_name: :string
      }
    end
    let(:entity_class) { domain_module::SomeEntity }

    it "creates an entity class" do
      domain_module.register_entities(entity_name => attributes_declaration)

      expect(entity_class).to be < Foobara::Entity

      entity_class.transaction do
        record = entity_class.create(first_name: "fn")
        expect(record).to be_a(domain_module::SomeEntity)
      end
    end
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
        organization
        domain = described_class.create("SomeOrg::SomeDomain")
        domain.mod
      }

      let(:command_class) {
        stub_class "#{domain_module.name}::SomeCommand", Foobara::Command do
          result(foo: :string, bar: :integer)
        end
      }

      describe "finding organization by name" do
        it "can find by name" do
          expect(Foobara.foobara_lookup_organization(:SomeOrg).scoped_name).to eq("SomeOrg")
        end
      end

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
        subject { organization.foobara_owns_domain?(domain) }

        it { is_expected.to be(true) }
      end

      # TODO: belongs elsewhere
      describe "#manifest" do
        it "gives a whole manifest of everything" do
          manifest = Foobara.manifest[:organizations][:SomeOrg][:domains][:SomeDomain][:commands][:SomeCommand]
          expect(manifest[:result_type][:element_type_declarations][:bar][:type]).to eq(:integer)

          expect(Foobara.foobara_all_organization).to include(organization)
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
    let(:model_class) do
      stub_class "#{domain_module.name}::SomeNewModel", Foobara::Model do
        attributes a: :integer, b: :symbol
      end
    end

    before do
      model_class
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
        model_manifest = manifest[:organizations][:global_organization][:domains][:SomeDomain][:types][:SomeNewModel]
        expect(model_manifest[:base_type]).to eq(:model)
        expect(model_manifest[:target_classes]).to eq(["SomeDomain::SomeNewModel"])
      end
    end
  end

  context "when creating a model from a module and an existing class but by name" do
    let(:model_class) do
      stub_class "#{domain_module.name}::SomeNewModel", Foobara::Model
    end

    it "automatically registers it" do
      type = domain_module.type_for_declaration(
        type: :model,
        name: model_class.model_name,
        model_module: domain_module,
        attributes_declaration: { a: :integer, b: :symbol }
      )
      expect(type.full_type_name).to eq("SomeDomain::SomeNewModel")
      expect(Foobara.all_types).to include(type)
    end
  end
end
