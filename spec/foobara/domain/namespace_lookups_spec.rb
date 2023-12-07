RSpec.describe "Foobara namespace lookup" do
  let(:number) { Foobara::TypeDeclarations::Namespace.current.type_for_declaration(:number) }

  before do
    # TODO: make this less awkward
    number.foobara_parent_namespace = Foobara
    Foobara.foobara_register(number)

    stub_class :GlobalError, Foobara::Error

    stub_class :Max, Foobara::Value::Processor
    stub_class "Max::TooBig", Foobara::Error

    stub_module :OrgA do
      foobara_organization!
    end

    stub_class "OrgA::DomainA" do
      foobara_domain!
    end
    custom_type_a = Foobara::TypeDeclarations::Namespace.current.type_for_declaration(
      a: :number,
      b: :string
    )
    custom_type_a.type_symbol = :custom
    custom_type_a.foobara_parent_namespace = OrgA::DomainA
    OrgA::DomainA.foobara_register(custom_type_a)

    stub_class "OrgA::DomainA::CommandA", Foobara::Command
    stub_class "OrgA::DomainA::CommandB", Foobara::Command

    stub_module "OrgA::DomainB" do
      foobara_domain!
    end
    custom_type_b = Foobara::TypeDeclarations::Namespace.current.type_for_declaration(
      c: :number,
      d: :string
    )
    custom_type_b.type_symbol = :custom
    custom_type_b.foobara_parent_namespace = OrgA::DomainB
    OrgA::DomainB.foobara_register(custom_type_b)

    stub_class "OrgA::DomainB::CommandA", Foobara::Command
    stub_class "OrgA::DomainB::CommandA::SomeError", Foobara::Error
    stub_class "OrgA::DomainB::CommandB", Foobara::Command
    stub_module "OrgA::DomainB::Foo"
    stub_module "OrgA::DomainB::Foo::Bar"
    stub_class "OrgA::DomainB::Foo::Bar::CommandA", Foobara::Command

    stub_module :OrgB do
      foobara_organization!
    end
    stub_class "OrgB::DomainA" do
      foobara_domain!
    end

    stub_class "OrgB::DomainA::CommandA", Foobara::Command
    stub_class "OrgB::DomainA::CommandB", Foobara::Command

    stub_module "OrgB::DomainB" do
      foobara_domain!
    end

    stub_class "OrgB::DomainB::CommandA", Foobara::Command
    stub_class "OrgB::DomainB::CommandA::SomeError", Foobara::Error
    stub_class "OrgB::DomainB::CommandB", Foobara::Command
    stub_module "OrgB::DomainB::Foo"
    stub_module "OrgB::DomainB::Foo::Bar"
    stub_class "OrgB::DomainB::Foo::Bar::CommandA", Foobara::Command

    stub_module :GlobalDomain do
      foobara_domain!
    end
    stub_class "GlobalDomain::CommandA", Foobara::Command
    stub_class "GlobalDomain::CommandB", Foobara::Command
    stub_module "GlobalDomain::Foo"
    stub_module "GlobalDomain::Foo::Bar"
    stub_class "GlobalDomain::Foo::Bar::CommandA", Foobara::Command
  end

  describe "#lookup_*" do
    it "finds the expected objects given certain paths", :focus do
      expect(OrgA.foobara_parent_namespace).to eq(Foobara)
      expect(OrgA.scoped_path).to eq(%w[OrgA])
      expect(OrgA.scoped_full_path).to eq(%w[OrgA])
      expect(Foobara.lookup_organization("OrgA")).to eq(OrgA)
      expect(Foobara.lookup_organization("::OrgA")).to eq(OrgA)

      expect(OrgA::DomainA.foobara_parent_namespace).to eq(OrgA)
      expect(OrgA::DomainA.scoped_path).to eq(%w[DomainA])
      expect(OrgA::DomainA.scoped_full_path).to eq(%w[OrgA DomainA])
      expect(OrgA::DomainA.scoped_full_name).to eq("::OrgA::DomainA")
      expect(
        Foobara.lookup_domain("OrgA::DomainA")
      ).to eq(OrgA::DomainA)
      expect(
        Foobara.lookup_domain("::OrgA::DomainA")
      ).to eq(OrgA::DomainA)

      expect(OrgA::DomainA.lookup_domain(:DomainA)).to eq(OrgA::DomainA)
      expect(OrgA::DomainA.lookup_domain("::DomainA")).to be_nil

      expect(
        OrgA::DomainA::CommandA.foobara_parent_namespace
      ).to eq(OrgA::DomainA)
      expect(OrgA::DomainA::CommandA.scoped_path).to eq(%w[CommandA])
      expect(OrgA::DomainA::CommandA.scoped_full_path).to eq(%w[OrgA DomainA CommandA])
      expect(
        OrgA::DomainA::CommandA.scoped_full_name
      ).to eq("::OrgA::DomainA::CommandA")
      expect(
        Foobara.lookup_command("OrgA::DomainA::CommandA")
      ).to eq(OrgA::DomainA::CommandA)
      expect(
        Foobara.lookup_command("::OrgA::DomainA::CommandA")
      ).to eq(OrgA::DomainA::CommandA)

      expect(GlobalError.scoped_namespace).to eq(Foobara)
      expect(GlobalError.scoped_path).to eq(%w[GlobalError])
      expect(GlobalError.scoped_full_path).to eq(%w[GlobalError])
      expect(
        Foobara.lookup_error("GlobalError")
      ).to eq(GlobalError)
      expect(
        Foobara.lookup_error("::GlobalError")
      ).to eq(GlobalError)

      expect(
        OrgA::DomainB::CommandA::SomeError.scoped_namespace
      ).to eq(OrgA::DomainB::CommandA)

      expect(number.foobara_parent_namespace).to eq(Foobara)
      expect(Foobara.lookup_type("number")).to eq(number)
      expect(Foobara.lookup_type("::number")).to eq(number)

      expect(Max.lookup("TooBig")).to eq(Max::TooBig)

      binding.pry
      expect(number.lookup_processor("max")).to eq(Max)
      expect(number.lookup_processor("max")).to eq(Max)
      expect(Foobara.lookup_processor("number::max")).to eq(Max)
      expect(Foobara.lookup_processor("::number::max")).to eq(Max)

      expect(Max.lookup_error("TooBig")).to eq(Max::TooBig)
      expect(
        Foobara.lookup_error("number::Max::TooBig")
      ).to eq(Max::TooBig)
    end
  end
end
