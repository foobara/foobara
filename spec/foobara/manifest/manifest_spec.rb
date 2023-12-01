RSpec.describe Foobara::Manifest do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    stub_class = ->(klass) { stub_const(klass.name, klass) }

    org = Module.new do
      def self.name
        "SomeOrg"
      end

      stub_class.call(self)
    end

    org.foobara_organization!

    dom = Module.new do
      def self.name
        "SomeOtherDomain"
      end

      stub_class.call(self)
    end

    dom.foobara_domain!

    Class.new(Foobara::Entity) do
      class << self
        def name
          "SomeOtherDomain::SomeOtherUser"
        end
      end

      stub_class.call(self)

      attributes id: :integer,
                 first_name: :string
      primary_key :id
    end

    dom = Module.new do
      def self.name
        "SomeOrg::SomeDomain"
      end

      stub_class.call(self)
    end

    dom.foobara_domain!
    dom.depends_on "SomeOtherDomain"

    Class.new(Foobara::Entity) do
      class << self
        def name
          "SomeOrg::SomeDomain::User"
        end
      end

      stub_class.call(self)

      attributes id: :integer,
                 name: { type: :string, required: true },
                 ratings: [:integer],
                 junk: { type: :associative_array, value_type_declaration: :array }
      primary_key :id
    end

    Class.new(Foobara::Command) do
      # rubocop:disable Lint/ConstantDefinitionInBlock, Lint/LeakyConstantDeclaration
      class SomethingWentWrongError < Foobara::RuntimeError
        class << self
          def context_type_declaration
            {}
          end
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock, Lint/LeakyConstantDeclaration

      class << self
        def name
          "SomeOrg::SomeDomain::QueryUser"
        end
      end

      stub_class.call(self)

      inputs user: SomeOrg::SomeDomain::User,
             some_other_user: SomeOtherDomain::SomeOtherUser
      result :User

      load_all

      possible_error SomethingWentWrongError
    end
  end

  let(:manifest) { Foobara::Manifest::RootManifest.new(raw_manifest) }
  let(:raw_manifest) { Foobara.manifest }
  let(:raw_stringified_manifest) { Foobara::Util.deep_stringify_keys(Foobara.manifest) }

  it "is a Manifest" do
    expect(manifest).to be_a(Foobara::Manifest::RootManifest)
    expect(manifest.global_domain).to be_global_domain

    entity = manifest.entity_by_name("User")

    expect(entity).to be_a(Foobara::Manifest::Entity)
    expect(manifest.entities).to include(entity)

    expect(entity.target_class).to eq("SomeOrg::SomeDomain::User")
    expect(entity.entity_manifest).to be_a(Hash)
    expect(entity.type_manifest).to be_a(Hash)

    attributes = entity.attributes_type
    expect(attributes).to be_a(Foobara::Manifest::Attributes)
    expect(attributes.required?("name")).to be(true)
    expect(attributes.required?("ratings")).to be(false)
    expect(attributes.required).to eq([:name])

    new_attributes = Foobara::Manifest::TypeDeclaration.new(attributes.root_manifest, attributes.path)
    expect(new_attributes).to be_a(Foobara::Manifest::Attributes)
    expect(new_attributes).to eql(attributes)
    expect(new_attributes.hash).to eql(attributes.hash)

    command = manifest.command_by_name("QueryUser")

    expect(command).to be_a(Foobara::Manifest::Command)
    expect(manifest.commands).to include(command)
    expect(command.command_manifest).to be_a(Hash)
    type_declaration = command.result_type
    expect(type_declaration.type).to eq(:User)
    expect(command.inputs_type).to be_a(Foobara::Manifest::Attributes)
    expect(command.inputs_type.required).to be_nil
    command = Foobara::Manifest::Command.new(raw_stringified_manifest, command.path)
    expect(command.inputs_type.required).to be_nil
    some_other_user_declaration = command.inputs_type.attribute_declarations[:some_other_user]
    expect(command.domain.find_type(some_other_user_declaration)).to be_a(Foobara::Manifest::Entity)

    global_error = command.error_types["data.cannot_cast"]
    expect(global_error).to be_a(Foobara::Manifest::Error)
    expect(global_error.error_manifest).to be_a(Hash)
    expect(global_error.symbol).to be_a(Symbol)
    expect(global_error).to be_global
    expect(global_error.organization_name).to eq("global_organization")
    expect(global_error.domain_name).to eq("global_domain")
    expect(global_error._path).to be_a(Array)

    local_error = command.error_types["runtime.something_went_wrong"]
    expect(local_error).to be_a(Foobara::Manifest::Error)
    expect(local_error).to_not be_global
    expect(local_error.organization_name).to eq("SomeOrg")
    expect(local_error.domain_name).to eq("SomeDomain")

    expect(type_declaration.type_declaration_manifest).to be_a(Hash)
    expect(type_declaration.to_entity).to be_a(Foobara::Manifest::Entity)

    domain = manifest.domain_by_name("SomeDomain")
    expect(domain).to be_a(Foobara::Manifest::Domain)
    expect(manifest.domains).to include(domain)
    expect(domain).to_not be_global_organization
    expect(domain).to_not be_global_domain
    expect(domain.domain_name_to_domain("SomeOrg::SomeDomain")).to eq(domain)

    org = manifest.organization_by_name("SomeOrg")
    expect(org).to be_a(Foobara::Manifest::Organization)
    expect(manifest.organizations).to include(org)
  end
end
