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

    stub_class "SomeOtherDomain::SomeDetachedEntity", Foobara::DetachedEntity do
      attributes do
        id :integer, :required
        foo :string, :required
        bar :string, :required
      end
      primary_key :id
    end

    stub_class "SomeOtherDomain::SomeOtherUser", Foobara::Entity do
      attributes do
        id :integer
        first_name :string, :allow_nil
        some_detached_entity SomeOtherDomain::SomeDetachedEntity, :required
      end
      primary_key :id
    end

    stub_module("SomeOrg::SomeDomain") do
      foobara_domain!
      foobara_depends_on "SomeOtherDomain"
    end

    stub_module "SomeOrg::SomeDomain::Types"

    stub_class "SomeOrg::SomeDomain::Types::Address", Foobara::Model do
      attributes do
        street :string
        city :string
        state :string
        zip :string
      end
    end

    stub_class "SomeOrg::SomeDomain::User", Foobara::Entity do
      attributes do
        id :integer
        name :string, :required
        phone :string, :allow_nil
        ratings [:integer], default: []
        junk :associative_array, value_type_declaration: :array
        address SomeOrg::SomeDomain::Types::Address
      end

      primary_key :id
    end

    stub_class "SomeOrg::SomeDomain::Referral", Foobara::Entity do
      attributes do
        id :integer
        user SomeOrg::SomeDomain::User
        channel :string
      end

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

    stub_class "SomeOrg::SomeDomain::QueryReferral", Foobara::Command do
      inputs id: :integer
      result :Referral
    end

    stub_class "GlobalError", Foobara::RuntimeError do
      class << self
        def context_type_declaration
          {}
        end
      end
    end

    stub_class "GlobalCommand", Foobara::Command do
      possible_error GlobalError
    end

    stub_class "CommandWithNoPossibleErrors", Foobara::Command do
      def execute
      end
    end
  end

  let(:manifest) { Foobara::Manifest::RootManifest.new(raw_manifest) }
  let(:raw_manifest) { Foobara.manifest }
  let(:raw_stringified_manifest) { Foobara::Util.deep_stringify_keys(Foobara.manifest) }

  it "is a Manifest" do
    integer = Foobara::Manifest::Type.new(raw_manifest, [:type, :integer])
    string = Foobara::Manifest::Type.new(raw_manifest, [:type, :string])

    expect(integer).to be_builtin

    expect(manifest).to be_a(Foobara::Manifest::RootManifest)
    expect(manifest.lookup_path(:command, :does_not_exist)).to be_nil
    expect(manifest.lookup(:does_not_exist)).to be_nil
    expect(manifest.global_domain).to be_global
    expect(manifest.scoped_category).to be_nil
    expect(manifest.parent).to be_nil

    domain = manifest.domain_by_name("SomeOrg::SomeDomain")
    expect(domain.full_domain_name).to eq("SomeOrg::SomeDomain")
    expect(domain).to be_a(Foobara::Manifest::Domain)
    expect(domain.scoped_category).to eq(:domain)
    expect(manifest.domains).to include(domain)
    expect(domain.domain_name).to eq("SomeDomain")

    expect(domain.organization).to_not be_global
    expect(domain).to_not be_global

    entity = manifest.entity_by_name("SomeOrg::SomeDomain::User")

    expect(entity).to be_a(Foobara::Manifest::Entity)
    expect(entity.full_type_name).to eq("SomeOrg::SomeDomain::User")
    expect(entity.full_entity_name).to eq("SomeOrg::SomeDomain::User")
    expect(entity.primary_key_name).to eq("id")

    expect(entity.relevant_manifest[:base_type]).to eq(:entity)
    expect(entity).to_not have_associations

    detached_entity = manifest.detached_entity_by_name("SomeOtherDomain::SomeDetachedEntity")
    expect(detached_entity).to be_a(Foobara::Manifest::DetachedEntity)
    expect(detached_entity.full_type_name).to eq("SomeOtherDomain::SomeDetachedEntity")
    expect(detached_entity.full_detached_entity_name).to eq("SomeOtherDomain::SomeDetachedEntity")
    expect(detached_entity.primary_key_name).to eq("id")
    expect(detached_entity).to_not have_associations
    expect(detached_entity).to be_detached_entity
    Foobara::Manifest::TypeDeclaration.new(raw_manifest, [*detached_entity.path, :declaration_data])
    some_other_domain = manifest.domain_by_name("SomeOtherDomain")
    #     expect(declaration.to_type).to be_detached_entity
    expect(some_other_domain.detached_entities).to include(detached_entity)
    some_other_user = manifest.type_by_name("SomeOtherDomain::SomeOtherUser")
    detached_entity_declaration = some_other_user.attributes_type.attribute_declarations[:some_detached_entity]
    expect(detached_entity_declaration).to be_detached_entity
    expect(detached_entity_declaration.to_detached_entity).to be_detached_entity
    expect(detached_entity_declaration.to_type).to be_detached_entity

    expect(entity.primary_key_type.to_type).to eq(integer)
    expect(entity.types_depended_on).to include(integer)
    expect(entity.scoped_category).to eq(:type)
    expect(entity.parent).to eq(domain)
    expect(manifest.entities).to include(entity)

    expect(entity.target_class).to eq("SomeOrg::SomeDomain::User")
    expect(entity.entity_manifest).to be_a(Hash)
    expect(entity.type_manifest).to be_a(Hash)
    expect(entity.attribute_names).to contain_exactly("name", "ratings", "junk", "phone", "address")

    expect(manifest.types).to include(entity)
    expect(entity.organization.types).to include(entity)
    expect(entity.to_type_declaration_from_declaration_data.name).to eq("User")

    attributes = entity.attributes_type
    expect(attributes).to_not be_custom
    expect(attributes.scoped_category).to be_nil
    expect(attributes.parent).to be_nil
    expect(attributes).to be_a(Foobara::Manifest::Attributes)
    expect(attributes.required?("name")).to be(true)
    expect(attributes.required?("ratings")).to be(false)
    expect(attributes.required).to eq([:name])
    expect(attributes.attribute_declarations[:ratings]).to be_array
    expect(attributes.attribute_declarations[:ratings].element_type.type).to eq(:integer)
    expect(attributes.attribute_declarations[:phone].allows_nil?).to be(true)

    attribute = attributes.attribute_declarations[:ratings]
    expect(attribute).to be_attribute
    expect(attribute.parent_attributes).to eq(attributes)
    expect(attribute.attribute_name).to eq(:ratings)
    expect(attribute).to_not be_required
    expect(attribute.default).to eq([])

    new_attributes = Foobara::Manifest::TypeDeclaration.new(attributes.root_manifest, attributes.path)
    expect(new_attributes).to be_a(Foobara::Manifest::Attributes)
    expect(new_attributes).to be_attributes
    expect(new_attributes).to eql(attributes)
    expect(new_attributes.hash).to eql(attributes.hash)

    entity_with_associations = manifest.entity_by_name("SomeOrg::SomeDomain::Referral")
    expect(entity_with_associations).to have_associations
    expect(entity_with_associations.associations[:user]).to eq(entity)

    model = manifest.model_by_name("SomeOrg::SomeDomain::Types::Address")

    expect(model).to be_a(Foobara::Manifest::Model)
    expect(model.model?).to be(true)
    expect(entity.attributes_type.attribute_declarations[:address].to_model).to eq(model)

    expect(model.types_depended_on).to include(string)
    expect(model.scoped_category).to eq(:type)
    expect(model.parent).to eq(domain)
    expect(manifest.models).to include(model)

    expect(model.target_class).to eq("SomeOrg::SomeDomain::Types::Address")
    expect(model.model_manifest).to be_a(Hash)
    expect(model.type_manifest).to be_a(Hash)
    expect(model.attribute_names).to contain_exactly("street", "city", "state", "zip")

    expect(manifest.types).to include(model)
    expect(model.organization.types).to include(model)
    expect(model.has_associations?).to be(false)
    expect(model.type_name).to eq("Types::Address")

    attributes = model.attributes_type
    expect(attributes.scoped_category).to be_nil
    expect(attributes.parent).to be_nil
    expect(attributes).to be_a(Foobara::Manifest::Attributes)
    expect(attributes.attribute_declarations[:street].type).to eq(:string)

    command = manifest.command_by_name("SomeOrg::SomeDomain::QueryUser")

    expect(command).to be_a(Foobara::Manifest::Command)
    expect(command.scoped_category).to eq(:command)
    expect(command.parent_category).to eq(:domain)
    expect(command.parent_name).to eq("SomeOrg::SomeDomain")
    expect(command.parent).to eq(domain)
    expect(command.requires_authentication?).to be false
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
      Foobara::Manifest::Type.new(raw_manifest, [:type, :attributes])
    )

    type_declaration = command.result_type
    expect(type_declaration.type).to eq(:"SomeOrg::SomeDomain::User")
    expect(type_declaration.type_declaration_manifest).to be_a(Hash)
    expect(type_declaration.to_entity).to be_a(Foobara::Manifest::Entity)
    expect(type_declaration.scoped_category).to be_nil
    expect(type_declaration.parent).to be_nil
    expect(type_declaration).to_not be_sensitive

    global_domain = Foobara::Manifest::Domain.new(raw_manifest, [:domain, "global_organization::global_domain"])

    global_command = manifest.command_by_name("GlobalCommand")
    expect(global_command).to be_a(Foobara::Manifest::Command)
    expect(global_command.full_command_name).to eq("GlobalCommand")
    expect(global_command.result_type).to be_nil
    expect(global_command.scoped_category).to eq(:command)
    expect(global_command.parent).to eq(global_domain)
    expect(global_command.domain).to eq(manifest.global_domain)
    expect(global_command.scoped_full_name).to eq("GlobalCommand")
    expect(global_command.domain.reference).to eq("global_organization::global_domain")
    expect(global_command.organization).to eq(manifest.global_organization)
    expect(global_command.inputs_type).to be_empty

    foobara_possible_error = command.possible_errors["data.cannot_cast"]
    expect(foobara_possible_error.scoped_category).to be_nil
    expect(foobara_possible_error.parent).to be_nil
    expect(foobara_possible_error._path).to eq([])
    expect(foobara_possible_error.processor_manifest_data).to be_a(Hash)
    expect(foobara_possible_error.manually_added).to be_falsey

    foobara_error = foobara_possible_error.error
    expect(foobara_error).to be_a(Foobara::Manifest::Error)
    expect(foobara_error.full_error_name).to eq("Foobara::Value::Processor::Casting::CannotCastError")
    expect(foobara_error.short_error_name).to eq("CannotCastError")
    expect(foobara_error.scoped_category).to eq(:error)
    expect(foobara_error.parent).to eq(
      Foobara::Manifest::ProcessorClass.new(
        raw_manifest,
        [:processor_class, "Foobara::Value::Processor::Casting"]
      )
    )
    expect(foobara_error.error_manifest).to be_a(Hash)
    expect(foobara_error.symbol).to be_a(Symbol)
    expect(foobara_error.organization.scoped_full_name).to eq("Foobara")
    expect(foobara_error.domain.scoped_full_name).to eq("Foobara::Value")
    expect(foobara_error.scoped_full_name).to eq("Foobara::Value::Processor::Casting::CannotCastError")
    expect(foobara_error.error_name).to eq("CannotCastError")
    expect(manifest.errors).to include(foobara_error)
    expect(foobara_error.abstract).to be_falsey

    local_possible_error = command.possible_errors["runtime.something_went_wrong"]
    expect(local_possible_error.scoped_category).to be_nil
    expect(local_possible_error.parent).to be_nil
    local_error = local_possible_error.error
    expect(local_error).to be_a(Foobara::Manifest::Error)
    expect(local_error.scoped_category).to eq(:error)
    expect(local_error.parent).to eq(command)
    expect(local_error.organization.scoped_full_name).to eq("SomeOrg")
    expect(local_error.domain.scoped_full_name).to eq("SomeOrg::SomeDomain")
    expect(local_error.scoped_name).to eq("SomethingWentWrongError")
    expect(local_error.scoped_full_name).to eq("SomeOrg::SomeDomain::QueryUser::SomethingWentWrongError")
    expect(local_error.types_depended_on.map(&:name)).to include(:attributes)

    global_error = Foobara::Manifest::Error.new(raw_manifest, [:error, "GlobalError"])

    expect(global_error).to be_a(Foobara::Manifest::Error)
    expect(global_error.scoped_category).to eq(:error)
    expect(global_error.parent).to eq(manifest.global_domain)
    expect(global_error.error_manifest).to be_a(Hash)
    expect(global_error.symbol).to be_a(Symbol)
    expect(global_error.organization).to eq(manifest.global_organization)
    expect(global_error.domain).to eq(manifest.global_domain)
    expect(global_error.scoped_full_name).to eq("GlobalError")
    expect(global_error.error_name).to eq("GlobalError")

    # TODO: disable this rubocop rule so we can just check against true
    expect(manifest).to be_contains("duck::SupportedCasters::AllowNil", :processor_class)
    processor_class = manifest.lookup_path(:processor_class, :"duck::SupportedCasters::AllowNil")
    expect(processor_class.full_processor_class_name).to eq("duck::SupportedCasters::AllowNil")

    processor = manifest.lookup("symbol::Casters::string")
    expect(processor.full_processor_name).to eq("symbol::Casters::string")

    org = manifest.organization_by_name("SomeOrg")
    expect(org.full_organization_name).to eq("SomeOrg")
    expect(org).to be_a(Foobara::Manifest::Organization)
    expect(org.scoped_category).to eq(:organization)
    expect(org.parent).to be_nil
    expect(manifest.organizations).to include(org)
    expect(org.organization_name).to eq("SomeOrg")

    command = manifest.command_by_name("CommandWithNoPossibleErrors")
    expect(command.possible_errors).to eq({})
  end
end
