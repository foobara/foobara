RSpec.describe "name space lookups of 'global' errors" do
  it "wires up global errors correctly" do
    expect(Foobara::RuntimeError.scoped_namespace).to be(Foobara::GlobalDomain)
    expect(
      Foobara::Namespace.global.foobara_lookup("Foobara::RuntimeError")
    ).to be(Foobara::RuntimeError)
  end
end
