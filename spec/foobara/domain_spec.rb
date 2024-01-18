RSpec.describe Foobara::Domain do
  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  after do
    Foobara.reset_alls
  end

  let(:organization) { stub_module(:SomeOrg) { foobara_organization! } }
  let(:domain) {
    stub_module :SomeDomain do
      foobara_domain!
    end
  }

  let!(:command_class) {
    stub_class "#{domain.name}::SomeCommand", Foobara::Command
  }

  describe ".to_domain" do
    context "when nil" do
      it "is the global domain" do
        expect(described_class.to_domain(nil)).to be(Foobara::GlobalDomain)
      end
    end

    context "when non-domain scoped to a domain" do
      before do
        stub_module "SomeDomain" do
          foobara_domain!
        end
        stub_class "SomeDomain::SomeError", Foobara::RuntimeError
      end

      it "returns that domain" do
        expect(described_class.to_domain(SomeDomain::SomeError)).to be(SomeDomain)
      end
    end
  end

  describe ".create" do
    after do
      Object.send(:remove_const, "SomeOrg")
    end

    it "creates a domain and its org" do
      expect(Object.const_defined?("SomeOrg::SomeDomain")).to be(false)
      described_class.create("SomeOrg::SomeDomain")

      expect(Object.const_defined?("SomeOrg::SomeDomain")).to be(true)

      expect(SomeOrg).to be_foobara_organization
      expect(SomeOrg::SomeDomain).to be_foobara_domain
    end

    context "when domain already exists" do
      it "raises an error" do
        described_class.create("SomeOrg::SomeDomain")

        expect {
          described_class.create("SomeOrg::SomeDomain")
        }.to raise_error(described_class::DomainAlreadyExistsError)
      end
    end
  end

  describe ".foobara_register_entity" do
    let(:entity_name) { :SomeEntity }
    let(:primary_key) { :id }
    let(:attributes_declaration) do
      {
        first_name: :string
      }
    end
    let(:entity_class) { domain::SomeEntity }

    it "creates an entity class" do
      domain.foobara_register_entities(entity_name => attributes_declaration)

      expect(entity_class).to be < Foobara::Entity

      entity_class.transaction do
        record = entity_class.create(first_name: "fn")
        expect(record).to be_a(domain::SomeEntity)
      end
    end
  end

  context "with simple command" do
    describe "#full_domain_name" do
      subject { domain.foobara_full_domain_name }

      it { is_expected.to eq("SomeDomain") }
    end

    describe "#foobara_full_domain_symbol" do
      subject { domain.foobara_full_domain_symbol }

      it { is_expected.to eq(:some_domain) }
    end

    context "with organization" do
      let(:domain) {
        stub_module "#{organization.name}::SomeDomain" do
          foobara_domain!
        end
      }

      let(:command_class) {
        stub_class "#{domain.foobara_full_domain_name}::SomeCommand", Foobara::Command do
          result(foo: :string, bar: :integer)
        end
      }

      describe "finding organization by name" do
        it "can find by name" do
          expect(Foobara.foobara_lookup_organization(:SomeOrg).scoped_name).to eq("SomeOrg")
        end
      end

      describe "#foobara_full_domain_name" do
        subject { domain.foobara_full_domain_name }

        it { is_expected.to eq("SomeOrg::SomeDomain") }
      end

      describe "#foobara_full_domain_symbol" do
        subject { domain.foobara_full_domain_symbol }

        it { is_expected.to eq(:"some_org::some_domain") }
      end

      # TODO: belongs elsewhere
      describe "#foobara_owns_domain?" do
        subject { organization.foobara_owns_domain?(domain) }

        it { is_expected.to be(true) }

        context "when does not own domain" do
          subject { other_org.foobara_owns_domain?(domain) }

          let(:other_org) do
            stub_module("SomeOtherOrg") { foobara_organization! }
          end

          it { is_expected.to be(false) }
        end
      end

      # TODO: belongs elsewhere
      describe "#manifest" do
        it "gives a whole manifest of everything" do
          manifest = Foobara.manifest[:command][:"SomeOrg::SomeDomain::SomeCommand"]
          expect(manifest[:result_type][:element_type_declarations][:bar][:type]).to eq(:integer)

          expect(Foobara.foobara_all_organization).to include(organization)
          expect(Foobara.foobara_all_domain).to include(domain)
          expect(Foobara.foobara_all_command).to include(command_class)
        end
      end

      describe "#foobara_command_classes" do
        subject { domain.foobara_command_classes }

        it { is_expected.to eq([command_class]) }
      end
    end
  end

  context "when creating a model in the domain module" do
    let(:model_class) do
      stub_class "#{domain.foobara_full_domain_name}::SomeNewModel", Foobara::Model do
        attributes a: :integer, b: :symbol
      end
    end

    before do
      model_class
    end

    it "automatically registers it" do
      expect(domain.const_get(:SomeNewModel).domain).to eq(domain)
      type = domain.foobara_type_namespace.type_for_declaration(:SomeNewModel)
      expect(type.full_type_name).to eq("SomeDomain::SomeNewModel")
      expect(Foobara.all_types).to include(type)
    end

    # TODO: this belongs elsewhere"
    describe ".manifest" do
      let(:manifest) { Foobara.manifest }

      it "gives a whole manifest of everything" do
        expect(manifest).to be_a(Hash)

        model_manifest = manifest[:type][:"SomeDomain::SomeNewModel"]
        expect(model_manifest[:base_type]).to eq(:model)
        expect(model_manifest[:target_classes]).to eq(["SomeDomain::SomeNewModel"])

        domain_manifest = manifest[:domain][:SomeDomain]
        expect(domain_manifest[:types]).to include("SomeDomain::SomeNewModel")
      end
    end
  end

  context "when creating a model from a module and an existing class but by name" do
    let(:model_class) do
      stub_class "#{domain.name}::SomeNewModel", Foobara::Model
    end

    it "automatically registers it" do
      type = domain.foobara_type_namespace.type_for_declaration(
        type: :model,
        name: model_class.model_name,
        model_module: domain,
        attributes_declaration: { a: :integer, b: :symbol }
      )
      expect(type.full_type_name).to eq("SomeDomain::SomeNewModel")
      expect(Foobara.all_types).to include(type)
    end
  end
end
