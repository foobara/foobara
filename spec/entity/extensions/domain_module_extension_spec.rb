RSpec.describe Foobara::Domain::DomainModuleExtension do
  after do
    Foobara.reset_alls
  end

  describe ".foobara_set_entity_base" do
    context "when using a prefix" do
      let(:org) do
        stub_module("SomeOrg") { foobara_organization! }
      end
      let(:domain) do
        org
        stub_module("SomeOrg::SomeDomain") { foobara_domain! }
      end
      let(:some_entity_class) do
        domain
        stub_class("SomeOrg::SomeDomain::SomeEntity", Foobara::Entity) do
          attributes do
            id :integer
            foo :integer
            bar :symbol
            created_at :datetime, :allow_nil
          end

          primary_key :id
        end
      end
      let(:driver_class) { Foobara::Persistence::CrudDrivers::InMemory }

      it "creates a base using the prefix and uses it for the entities in that domain" do
        base = domain.foobara_set_entity_base(driver_class, prefix: "some_prefix")
        expect(domain.foobara_default_entity_base).to be(base)

        expect(some_entity_class.entity_base).to be(base)

        expect(
          base.entity_attributes_crud_driver.table_for(some_entity_class).table_name
        ).to eq("some_prefix_some_entity")
      end
    end
  end
end
