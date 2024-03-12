RSpec.describe "Command namespacing" do
  let(:organization_module) do
    stub_module(:SomeOrg)
  end

  let(:domain_module) do
    organization_module
    stub_module("SomeOrg::SomeDomain")
  end

  let(:command_class) do
    domain_module
    stub_class("SomeOrg::SomeDomain::SomeCommand", Foobara::Command)
  end

  context "when org and domain are created first" do
    before do
      organization_module.foobara_organization!
      domain_module.foobara_domain!
      command_class
    end

    it "has all the namespaces wired up properly" do
      expect(command_class.scoped_namespace).to eq(domain_module)
      expect(command_class.foobara_parent_namespace).to eq(domain_module)
      expect(command_class.foobara_domain).to eq(domain_module)
      expect(command_class.foobara_organization).to eq(organization_module)
      expect(organization_module.foobara_all_domain).to eq([domain_module])
      expect(organization_module.foobara_children).to eq([domain_module])
      expect(organization_module.foobara_all_command).to eq([command_class])
      expect(domain_module.foobara_all_command).to eq([command_class])
      expect(domain_module.foobara_children).to eq([command_class])
      expect(domain_module.foobara_parent_namespace).to eq(organization_module)
    end
  end

  context "when org and domain are created after" do
    before do
      command_class
      domain_module.foobara_domain!
      organization_module.foobara_organization!
    end

    it "has all the namespaces wired up properly" do
      expect(command_class.scoped_namespace).to eq(domain_module)
      expect(command_class.foobara_parent_namespace).to eq(domain_module)
      expect(command_class.foobara_domain).to eq(domain_module)
      expect(command_class.foobara_organization).to eq(organization_module)
      expect(organization_module.foobara_all_domain).to eq([domain_module])
      expect(organization_module.foobara_children).to eq([domain_module])
      expect(organization_module.foobara_all_command).to eq([command_class])
      expect(domain_module.foobara_all_command).to eq([command_class])
      expect(domain_module.foobara_children).to eq([command_class])
      expect(domain_module.scoped_namespace).to eq(organization_module)
      expect(domain_module.foobara_parent_namespace).to eq(organization_module)
    end
  end
end
