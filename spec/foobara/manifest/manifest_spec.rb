RSpec.describe Foobara::Manifest do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

    stub_module :SomeOrg do
      foobara_organization!
    end

    stub_module :SomeOtherDomain do
      foobara_domain!
    end

    stub_class "SomeOtherDomain::SomeOtherUser", Foobara::Entity do
      attributes id: :integer,
                 first_name: :string
      primary_key :id
    end

    stub_module("SomeOrg::SomeDomain") do
      foobara_domain!
      foobara_depends_on "SomeOtherDomain"
    end

    stub_class "SomeOrg::SomeDomain::User", Foobara::Entity do
      attributes id: :integer,
                 name: { type: :string, required: true },
                 ratings: [:integer],
                 junk: { type: :associative_array, value_type_declaration: :array }
      primary_key :id
    end

    stub_class "SomeOrg::SomeDomain::QueryUser", Foobara::Command
    stub_class "SomeOrg::SomeDomain::QueryUser::SomethingWentWrongError", Foobara::RuntimeError do
      class << self
        def context_type_declaration
          {}
        end
      end
    end

    SomeOrg::SomeDomain::QueryUser.class_eval do
      inputs user: SomeOrg::SomeDomain::User,
             some_other_user: SomeOtherDomain::SomeOtherUser
      result :User

      load_all

      possible_error SomeOrg::SomeDomain::QueryUser::SomethingWentWrongError
    end

    stub_class "GlobalCommand", Foobara::Command
  end

  let(:manifest) { Foobara::Manifest::RootManifest.new(raw_manifest) }
  let(:raw_manifest) { Foobara.manifest }
  let(:raw_stringified_manifest) { Foobara::Util.deep_stringify_keys(Foobara.manifest) }

  it "is a Manifest" do
    integer = Foobara::Manifest::Type.new(raw_manifest, %i[type integer])

    expect(manifest).to be_a(Foobara::Manifest::RootManifest)
    expect(manifest.global_domain).to be_global
    expect(manifest.scoped_category).to be_nil
    expect(manifest.parent).to be_nil

    domain = manifest.domain_by_name("SomeOrg::SomeDomain")
    expect(domain).to be_a(Foobara::Manifest::Domain)
    expect(domain.scoped_category).to eq(:domain)
    expect(manifest.domains).to include(domain)

    expect(domain.organization).to_not be_global
    expect(domain).to_not be_global
    expect(domain.domain_name_to_domain("SomeOrg::SomeDomain")).to eq(domain)

    entity = manifest.entity_by_name("SomeOrg::SomeDomain::User")

    expect(entity).to be_a(Foobara::Manifest::Entity)
    expect(entity.primary_key_name).to eq("id")
    expect(entity.has_associations?).to be(false)

    expect(entity.primary_key_type.to_type).to eq(integer)
    expect(entity.types_depended_on).to include(integer)
    expect(entity.scoped_category).to eq(:type)
    expect(entity.parent).to eq(domain)
    expect(manifest.entities).to include(entity)

    expect(entity.target_class).to eq("SomeOrg::SomeDomain::User")
    expect(entity.entity_manifest).to be_a(Hash)
    expect(entity.type_manifest).to be_a(Hash)
    expect(entity.attribute_names).to match_array(%w[name ratings junk])

    expect(manifest.types).to include(entity)
    expect(entity.organization.types).to include(entity)

    attributes = entity.attributes_type
    expect(attributes.scoped_category).to be_nil
    expect(attributes.parent).to be_nil
    expect(attributes).to be_a(Foobara::Manifest::Attributes)
    expect(attributes.required?("name")).to be(true)
    expect(attributes.required?("ratings")).to be(false)
    expect(attributes.required).to eq([:name])
    expect(attributes.attribute_declarations[:ratings].element_type.type).to eq(:integer)

    new_attributes = Foobara::Manifest::TypeDeclaration.new(attributes.root_manifest, attributes.path)
    expect(new_attributes).to be_a(Foobara::Manifest::Attributes)
    expect(new_attributes).to eql(attributes)
    expect(new_attributes.hash).to eql(attributes.hash)

    command = manifest.command_by_name("SomeOrg::SomeDomain::QueryUser")

    expect(command).to be_a(Foobara::Manifest::Command)
    expect(command.scoped_category).to eq(:command)
    expect(command.parent_category).to eq(:domain)
    expect(command.parent_name).to eq("SomeOrg::SomeDomain")
    expect(entity.parent).to eq(domain)
    expect(command.command_name).to eq("QueryUser")
    expect(manifest.commands).to include(command)
    expect(command.command_manifest).to be_a(Hash)
    expect(command.inputs_type).to be_a(Foobara::Manifest::Attributes)
    expect(command.inputs_type.required).to be_nil
    command = Foobara::Manifest::Command.new(raw_stringified_manifest, command.path)
    expect(command.inputs_type.required).to be_nil
    some_other_user_declaration = command.inputs_type.attribute_declarations[:some_other_user]
    expect(command.domain.find_type(some_other_user_declaration)).to be_a(Foobara::Manifest::Entity)
    expect(command.types_depended_on).to include(entity)
    expect(command.inputs_types_depended_on).to include(entity)
    expect(command.result_types_depended_on).to include(entity)
    expect(command.errors_types_depended_on).to include(
      Foobara::Manifest::Type.new(raw_manifest, %i[type attributes])
    )

    type_declaration = command.result_type
    expect(type_declaration.type).to eq(:"SomeOrg::SomeDomain::User")
    expect(type_declaration.type_declaration_manifest).to be_a(Hash)
    expect(type_declaration.to_entity).to be_a(Foobara::Manifest::Entity)
    expect(type_declaration.scoped_category).to be_nil
    expect(type_declaration.parent).to be_nil

    global_domain = Foobara::Manifest::Domain.new(raw_manifest, [:domain, "global_organization::global_domain"])

    global_command = manifest.command_by_name("GlobalCommand")
    expect(global_command).to be_a(Foobara::Manifest::Command)
    expect(global_command.scoped_category).to eq(:command)
    expect(global_command.parent).to eq(global_domain)
    expect(global_command.domain_name).to eq("global_domain")
    expect(global_command.scoped_full_name).to eq("GlobalCommand")
    expect(global_command.domain.reference).to eq("global_organization::global_domain")
    expect(global_command.organization_name).to eq("global_organization")

    global_possible_error = command.error_types["data.cannot_cast"]
    expect(global_possible_error.scoped_category).to be_nil
    expect(global_possible_error.parent).to be_nil
    expect(global_possible_error._path).to be_a(Array)
    global_error = global_possible_error.error
    expect(global_error).to be_a(Foobara::Manifest::Error)
    expect(global_error.scoped_category).to eq(:error)
    expect(global_error.parent).to eq(
      Foobara::Manifest::ProcessorClass.new(raw_manifest, [:processor_class, "Value::Processor::Casting"])
    )
    expect(global_error.error_manifest).to be_a(Hash)
    expect(global_error.symbol).to be_a(Symbol)
    expect(global_error.organization.organization_name).to eq(manifest.global_organization.organization_name)
    expect(global_error.organization_name).to eq("global_organization")
    expect(global_error.domain_name).to eq("global_domain")
    expect(global_error.error_name).to eq("CannotCastError")

    local_possible_error = command.error_types["runtime.something_went_wrong"]
    expect(local_possible_error.scoped_category).to be_nil
    expect(local_possible_error.parent).to be_nil
    local_error = local_possible_error.error
    expect(local_error).to be_a(Foobara::Manifest::Error)
    expect(local_error.scoped_category).to eq(:error)
    expect(local_error.parent).to eq(command)
    expect(local_error.organization_name).to eq("SomeOrg")
    expect(local_error.domain_name).to eq("SomeDomain")
    expect(local_error.error_name).to eq("SomethingWentWrongError")

    org = manifest.organization_by_name("SomeOrg")
    expect(org).to be_a(Foobara::Manifest::Organization)
    expect(org.scoped_category).to eq(:organization)
    expect(org.parent).to be_nil
    expect(manifest.organizations).to include(org)
  end
end
