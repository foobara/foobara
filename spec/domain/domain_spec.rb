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

  describe ".to_organization" do
    context "when nil" do
      it "is the global organization" do
        expect(Foobara::Organization.to_organization(nil)).to be(Foobara::GlobalOrganization)
      end
    end

    context "when non-organization scoped to a organization" do
      before do
        stub_module "SomeOrganization" do
          foobara_organization!
        end
        stub_class "SomeOrganization::SomeError", Foobara::RuntimeError
      end

      it "returns that organization" do
        expect(Foobara::Organization.to_organization(SomeOrganization::SomeError)).to be(SomeOrganization)
      end

      context "when lookup by symbol" do
        it "returns the expected org" do
          expect(Foobara::Organization.to_organization(:SomeOrganization)).to be(SomeOrganization)
        end
      end

      context "when has no org" do
        let(:scoped) do
          stub_class(:SomeScoped) do
            extend Foobara::Scoped
          end
        end

        it "returns global org" do
          expect(Foobara::Organization.to_organization(scoped)).to be(Foobara::GlobalOrganization)
        end
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

  describe "Organization.create" do
    after do
      Object.send(:remove_const, "A") if Object.const_defined?("A")
    end

    context "when organization parent modules don't exist" do
      before do
        stub_module("A")
      end

      it "creates the org with its parent modules" do
        Foobara::Organization.create("A::B::C::D")

        expect(A::B).to be_a(Module)
        expect(A::B::C).to be_a(Module)
        expect(A::B::C::D).to be_a(Module)
        expect(A::B::C::D).to be_foobara_organization
      end
    end
  end

  describe ".foobara_register_type" do
    let(:type_symbol) { :some_type }
    let(:type_declaration) { [:string, :downcase] }

    it "creates and registers a type and puts it on the Types module" do
      domain.foobara_register_type(type_symbol, *type_declaration)

      type = domain.foobara_lookup(type_symbol)

      expect(type.process_value!("FooBarBaz")).to eq("foobarbaz")
      expect(SomeDomain::Types.some_type).to be(type)
    end

    context "when registering a Type instead of a type declaration" do
      it "registers the type" do
        new_type = domain.foobara_type_from_declaration(*type_declaration)

        domain.foobara_register_type(type_symbol, new_type)

        type = domain.foobara_lookup(type_symbol)

        expect(type.process_value!("FooBarBaz")).to eq("foobarbaz")
        expect(SomeDomain::Types.some_type).to be(type)
      end
    end

    context "when registering a strict stringified declaration" do
      let(:type_declaration) do
        { "downcase" => true, "type" => "string" }
      end

      it "registers the type" do
        type = domain.foobara_type_from_strict_stringified_declaration(type_declaration)

        domain.foobara_register_type(type_symbol, type)

        expect(type.process_value!("FooBarBaz")).to eq("foobarbaz")
        expect(SomeDomain::Types.some_type).to be(type)
      end
    end

    context "when registering a strict declaration" do
      let(:type_declaration) do
        { downcase: true, type: :string }
      end

      it "registers the type" do
        type = domain.foobara_type_from_strict_declaration(type_declaration)

        domain.foobara_register_type(type_symbol, type)

        expect(type.process_value!("FooBarBaz")).to eq("foobarbaz")
        expect(SomeDomain::Types.some_type).to be(type)
      end
    end

    context "when type constant is upper case" do
      let(:type_symbol) { "SomeType" }

      it "creates and registers a type and puts it on the Types module as a constant" do
        domain.foobara_register_type(type_symbol, *type_declaration)

        type = domain.foobara_lookup(type_symbol)
        expect(type).to be_a(Foobara::Types::Type)
        expect(SomeDomain::Types::SomeType).to be(type)
      end
    end

    context "when registering on the GlobalDomain" do
      it "creates and registers the type and puts it on the Types module" do
        type = Foobara::GlobalDomain.foobara_register_type(type_symbol, *type_declaration)
        expect(type).to be_a(Foobara::Types::Type)
        expect(Foobara::GlobalDomain::Types.some_type).to be(type)
      end
    end

    context "when another model will be nested within it" do
      let(:some_other_domain) do
        stub_module("SomeOtherDomain")
      end
      let(:inner_type_declaration) do
        { type: :string, downcase: true }
      end
      let(:inner_model_declaration) do
        some_other_domain
        {
          type: :model,
          name: "SomeOuterModel::SomeInnerModel",
          model_module: "SomeOtherDomain",
          attributes_declaration: { first_name: { type: :string } }
        }
      end
      let(:outer_model_declaration) do
        some_other_domain
        {
          type: :model,
          name: "SomeOuterModel",
          model_module: "SomeOtherDomain",
          attributes_declaration: { last_name: { type: :string } }
        }
      end

      it "upgrades the outer type from a module to a model class" do
        inner_model = Foobara::GlobalDomain.foobara_register_type(
          ["SomeOtherDomain", "SomeOuterModel", "SomeInnerModel"],
          inner_model_declaration
        )
        Foobara::Model.deanonymize_class(inner_model.target_class)
        inner_type = Foobara::GlobalDomain.foobara_register_type(
          ["SomeOtherDomain", "SomeOuterModel", "some_inner_type"],
          inner_type_declaration
        )

        expect(SomeOtherDomain::SomeOuterModel).to be_a(Module)
        expect(SomeOtherDomain::SomeOuterModel).to_not be_a(Class)
        expect(SomeOtherDomain::SomeOuterModel.instance_variable_get(:@foobara_created_via_make_class)).to be(true)
        expect(Foobara::GlobalDomain::Types::SomeOtherDomain::SomeOuterModel).to be_a(Module)
        expect(Foobara::GlobalDomain::Types::SomeOtherDomain::SomeOuterModel).to_not be_a(Class)
        expect(
          Foobara::GlobalDomain::Types::SomeOtherDomain::SomeOuterModel.instance_variable_get(
            :@foobara_created_via_make_class
          )
        ).to be(true)
        expect(Foobara::GlobalDomain::Types::SomeOtherDomain::SomeOuterModel.some_inner_type).to be(inner_type)
        expect(Foobara::GlobalDomain::Types::SomeOtherDomain::SomeOuterModel::SomeInnerModel).to be_a(Class)
        expect(SomeOtherDomain::SomeOuterModel::SomeInnerModel).to be_a(Class)
        expect(SomeOtherDomain::SomeOuterModel::SomeInnerModel.model_type).to be(inner_model)

        outer_model = Foobara::GlobalDomain.foobara_register_type(["SomeOtherDomain", "SomeOuterModel"],
                                                                  outer_model_declaration)
        Foobara::Model.deanonymize_class(outer_model.target_class)

        expect(SomeOtherDomain::SomeOuterModel).to be_a(Class)
        expect(SomeOtherDomain::SomeOuterModel.model_type).to be(outer_model)
        expect(Foobara::GlobalDomain::Types::SomeOtherDomain::SomeOuterModel).to be_a(Class)
        expect(Foobara::GlobalDomain::Types::SomeOtherDomain::SomeOuterModel.model_type).to be(outer_model)
        expect(Foobara::GlobalDomain::Types::SomeOtherDomain::SomeOuterModel.some_inner_type).to be(inner_type)
        expect(SomeOtherDomain::SomeOuterModel::SomeInnerModel).to be_a(Class)
        expect(SomeOtherDomain::SomeOuterModel::SomeInnerModel.model_type).to be(inner_model)

        some_other_domain.foobara_domain!

        expect(SomeOtherDomain::SomeOuterModel).to be_a(Class)
        expect(SomeOtherDomain::SomeOuterModel.model_type).to be(outer_model)
        expect(SomeOtherDomain::Types::SomeOuterModel).to be_a(Class)
        expect(SomeOtherDomain::Types::SomeOuterModel.model_type).to be(outer_model)
        expect(SomeOtherDomain::Types::SomeOuterModel.some_inner_type).to be(inner_type)
        expect(SomeOtherDomain::SomeOuterModel::SomeInnerModel).to be_a(Class)
        expect(SomeOtherDomain::SomeOuterModel::SomeInnerModel.model_type).to be(inner_model)

        expect(Foobara::GlobalDomain.constants(false)).to_not include(:Types)
      end
    end

    context "when it already has a Types prefix" do
      let(:type_symbol) { [:Types, :Foo, :Bar, :some_type] }

      it "creates and registers the type and puts it on the existing Types module" do
        domain.foobara_register_type(type_symbol, *type_declaration)

        type = domain.foobara_lookup(type_symbol)

        expect(type).to be_a(Foobara::Types::Type)
        expect(SomeDomain::Types::Foo::Bar.some_type).to be(type)
      end

      context "when the Types module already exists" do
        before do
          stub_module("SomeDomain::Types")
        end

        it "creates and registers the type and puts it on the existing Types module" do
          domain.foobara_register_type(type_symbol, *type_declaration)

          type = domain.foobara_lookup(type_symbol)

          expect(type).to be_a(Foobara::Types::Type)
          expect(SomeDomain::Types::Foo::Bar.some_type).to be(type)
        end
      end
    end
  end

  describe ".foobara_register_entities" do
    let(:entity_name) { :SomeEntity }
    let(:primary_key) { :id }
    let(:attributes_declaration) do
      {
        first_name: :string
      }
    end
    let(:entity_class) { domain.foobara_lookup!(:SomeEntity).target_class }

    it "creates an entity class" do
      domain.foobara_register_entities(entity_name => attributes_declaration)

      expect(entity_class).to be < Foobara::Entity

      entity_class.transaction do
        record = entity_class.create(first_name: "fn")
        expect(record).to be_a(entity_class)
      end
    end

    context "when passing a block" do
      it "creates an entity class" do
        base_entity_class = domain.foobara_register_entity(:Base, "some base entity") do
          id :integer
        end

        domain.foobara_register_entity(entity_name, base_entity_class, "Some description") do
          first_name :string
        end

        expect(entity_class).to be < Foobara::Entity
        expect(entity_class.description).to eq("Some description")

        entity_class.transaction do
          record = entity_class.create(first_name: "fn")
          expect(record).to be_a(entity_class)
        end
      end
    end
  end

  describe ".foobara_register_and_deanonymize_entities" do
    let(:entity_name) { :SomeEntity }
    let(:primary_key) { :id }
    let(:attributes_declaration) do
      {
        first_name: :string
      }
    end
    let(:entity_class) { domain.foobara_lookup!(:SomeEntity).target_class }

    it "creates an entity class" do
      domain.foobara_register_and_deanonymize_entities(entity_name => attributes_declaration)

      expect(entity_class).to be < Foobara::Entity

      entity_class.transaction do
        record = entity_class.create(first_name: "fn")
        expect(record).to be_a(entity_class)
      end
    end

    context "when passing a block" do
      it "creates an entity class" do
        base_entity_class = domain.foobara_register_entity(:Base, "some base entity") do
          id :integer
        end

        domain.foobara_register_entity(entity_name, base_entity_class, "Some description") do
          first_name :string
        end

        expect(entity_class).to be < Foobara::Entity
        expect(entity_class.description).to eq("Some description")

        entity_class.transaction do
          record = entity_class.create(first_name: "fn")
          expect(record).to be_a(entity_class)
        end
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
          result do
            foo :string
            bar :integer
          end
        end
      }

      describe "finding organization by name" do
        it "can find by name" do
          expect(Foobara::Namespace.global.foobara_lookup_organization(:SomeOrg).scoped_name).to eq("SomeOrg")
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

          expect(Foobara.all_organizations).to include(organization)
          expect(Foobara.all_domains).to include(domain)
          expect(Foobara.all_commands).to include(command_class)
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
      type = domain.foobara_lookup_type!(:SomeNewModel)
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
      type = domain.foobara_type_from_declaration(
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
