RSpec.describe Foobara::Domain::DomainModuleExtension do
  after do
    Foobara.reset_alls
  end

  describe ".foobara_register_type" do
    context "when a custom type has been added to the global domain and then removed" do
      before do
        Foobara::GlobalDomain.foobara_register_type(["Foo", "Bar", "whatever"], :string, :downcase)
        Foobara.reset_alls
      end

      # This is a confusing test for a confusing code path that might not be necessary.
      it "upgrades the outer type from a module to a model class" do
        stub_module("SomeOtherDomain")

        Foobara::GlobalDomain.foobara_register_type(
          ["SomeOtherDomain", "SomeOuterModel", "SomeInnerModel"],
          type: :model,
          name: "SomeOuterModel::SomeInnerModel",
          model_module: "SomeOtherDomain",
          attributes_declaration: { first_name: { type: :string } }
        )

        SomeOtherDomain.foobara_domain!

        expect(SomeOtherDomain).to be_foobara_domain
      end
    end
  end
end
