RSpec.describe Foobara::CommandConnectors::Http do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

    stub_module :DomainA do
      foobara_domain!
    end

    stub_module :DomainB do
      foobara_domain!
    end

    stub_class(:User, Foobara::Entity) do
      attributes id: :integer, name: :string
      primary_key :id
    end

    stub_class("DomainA::User", Foobara::Entity) do
      attributes id: :integer, name: :string
      primary_key :id
    end

    stub_class("DomainB::User", Foobara::Entity) do
      attributes id: :integer, name: :string
      primary_key :id
    end

    stub_class(:SomeCommand, Foobara::Command) do
      depends_on_entities(User)
    end

    stub_class("DomainA::SomeCommand", Foobara::Command) do
      description "Some Command Description"

      depends_on_entities(User, DomainA::User)
    end

    stub_class("DomainB::SomeCommand", Foobara::Command) do
      depends_on_entities(User, DomainB::User)
    end

    command_connector.connect(SomeCommand)
    command_connector.connect(DomainA::SomeCommand)
    command_connector.connect(DomainB::SomeCommand)
  end

  let(:command_connector) { described_class.new }

  describe "#transformed_command_from_name" do
    it "can find the correct command or type despite ambiguities" do
      expect(command_connector.lookup_command("SomeCommand").command_class).to eq(SomeCommand)
      expect(command_connector.lookup_command(:SomeCommand).command_class).to eq(SomeCommand)
      expect(
        command_connector.lookup_command("DomainA::SomeCommand").command_class
      ).to eq(DomainA::SomeCommand)
      expect(
        command_connector.lookup_command(:"DomainA::SomeCommand").command_class
      ).to eq(DomainA::SomeCommand)
      expect(
        command_connector.lookup_command("DomainB::SomeCommand").command_class
      ).to eq(DomainB::SomeCommand)
      expect(
        command_connector.lookup_command(:"DomainB::SomeCommand").command_class
      ).to eq(DomainB::SomeCommand)

      expect(command_connector.type_from_name("User").target_class).to eq(User)
      expect(command_connector.type_from_name(:User).target_class).to eq(User)
      expect(command_connector.type_from_name("DomainA::User").target_class).to eq(DomainA::User)
      expect(command_connector.type_from_name(:"DomainA::User").target_class).to eq(DomainA::User)
      expect(command_connector.type_from_name("DomainB::User").target_class).to eq(DomainB::User)
      expect(command_connector.type_from_name(:"DomainB::User").target_class).to eq(DomainB::User)
    end
  end

  describe "when connecting a command twice but with a suffix" do
    before do
      command_connector.connect(DomainA::SomeCommand, suffix: "Again")
    end

    it "registers it again but with the new name" do
      some_command = command_connector.lookup_command("DomainA::SomeCommand")
      some_command_again = command_connector.lookup_command("DomainA::SomeCommandAgain")

      expect(some_command.command_class).to eq(DomainA::SomeCommand)
      expect(some_command_again.command_class).to eq(DomainA::SomeCommand)
      expect(some_command.command_name).to eq("SomeCommand")
      expect(some_command_again.command_name).to eq("SomeCommandAgain")
      expect(some_command_again.command_class.command_name).to eq("SomeCommand")

      manifest = some_command_again.foobara_manifest(to_include: Set.new)

      expect(manifest[:scoped_path]).to eq(["SomeCommandAgain"])
      expect(manifest[:scoped_name]).to eq("SomeCommandAgain")
      expect(manifest[:scoped_short_name]).to eq("SomeCommandAgain")
      expect(manifest[:scoped_prefix]).to be_nil
      expect(manifest[:scoped_full_path]).to eq(%w[DomainA SomeCommandAgain])
      expect(manifest[:scoped_full_name]).to eq("DomainA::SomeCommandAgain")
      expect(manifest[:scoped_category]).to eq(:command)
      expect(manifest[:reference]).to eq("DomainA::SomeCommandAgain")
      expect(manifest[:domain]).to eq("DomainA")
      expect(manifest[:organization]).to eq("global_organization")
      expect(manifest[:parent]).to eq([:domain, "DomainA"])
      expect(manifest[:types_depended_on]).to be_an(Array)
      expect(manifest[:full_command_name]).to eq("DomainA::SomeCommandAgain")
      expect(manifest[:inputs_type]).to be_a(Hash)
      expect(manifest[:description]).to eq("Some Command Description")
      expect(manifest[:domain_name]).to eq("DomainA")
      expect(manifest[:organization_name]).to eq("global_organization")
      expect(manifest[:errors_transformers]).to be_nil
    end

    it "includes the suffixed commands in the manifest" do
      manifest = command_connector.foobara_manifest

      domain_manifest = manifest[:domain][:DomainA]
      commands_list = domain_manifest[:commands]

      expect(commands_list).to eq([
                                    "DomainA::SomeCommand",
                                    "DomainA::SomeCommandAgain"
                                  ])
    end
  end
end
