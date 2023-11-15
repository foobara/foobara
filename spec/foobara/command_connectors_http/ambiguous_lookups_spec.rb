Foobara::Monorepo.project :command_connectors_http

RSpec.describe Foobara::CommandConnectors::Http do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

    stub_class = ->(klass) { stub_const(klass.name, klass) }

    Module.new do
      class << self
        def name
          "DomainA"
        end
      end

      stub_class.call(self)

      foobara_domain!
    end

    Module.new do
      class << self
        def name
          "DomainB"
        end
      end

      stub_class.call(self)

      foobara_domain!
    end

    Class.new(Foobara::Entity) do
      class << self
        def name
          "User"
        end
      end

      stub_class.call(self)

      attributes id: :integer, name: :string
      primary_key :id
    end

    Class.new(Foobara::Entity) do
      class << self
        def name
          "DomainA::User"
        end
      end

      stub_class.call(self)

      attributes id: :integer, name: :string
      primary_key :id
    end

    Class.new(Foobara::Entity) do
      class << self
        def name
          "DomainB::User"
        end
      end

      stub_class.call(self)

      attributes id: :integer, name: :string
      primary_key :id
    end

    Class.new(Foobara::Command) do
      class << self
        def name
          "SomeCommand"
        end
      end

      stub_class.call(self)

      depends_on_entities(User)
    end

    Class.new(Foobara::Command) do
      class << self
        def name
          "DomainA::SomeCommand"
        end
      end

      stub_class.call(self)

      depends_on_entities(User, DomainA::User)
    end

    Class.new(Foobara::Command) do
      class << self
        def name
          "DomainB::SomeCommand"
        end
      end

      stub_class.call(self)

      depends_on_entities(User, DomainB::User)
    end

    command_connector.connect(SomeCommand)
    command_connector.connect(DomainA::SomeCommand)
    command_connector.connect(DomainB::SomeCommand)
  end

  let(:command_connector) { described_class.new }

  describe "#transformed_command_from_name" do
    it "can find the correct command or type despite ambiguities" do
      expect(command_connector.transformed_command_from_name("SomeCommand").command_class).to eq(SomeCommand)
      expect(command_connector.transformed_command_from_name(:SomeCommand).command_class).to eq(SomeCommand)
      expect(
        command_connector.transformed_command_from_name("DomainA::SomeCommand").command_class
      ).to eq(DomainA::SomeCommand)
      expect(
        command_connector.transformed_command_from_name(:"DomainA::SomeCommand").command_class
      ).to eq(DomainA::SomeCommand)
      expect(
        command_connector.transformed_command_from_name("DomainB::SomeCommand").command_class
      ).to eq(DomainB::SomeCommand)
      expect(
        command_connector.transformed_command_from_name(:"DomainB::SomeCommand").command_class
      ).to eq(DomainB::SomeCommand)

      expect(command_connector.type_from_name("User").target_class).to eq(User)
      expect(command_connector.type_from_name(:User).target_class).to eq(User)
      expect(command_connector.type_from_name("DomainA::User").target_class).to eq(DomainA::User)
      expect(command_connector.type_from_name(:"DomainA::User").target_class).to eq(DomainA::User)
      expect(command_connector.type_from_name("DomainB::User").target_class).to eq(DomainB::User)
      expect(command_connector.type_from_name(:"DomainB::User").target_class).to eq(DomainB::User)
    end
  end
end