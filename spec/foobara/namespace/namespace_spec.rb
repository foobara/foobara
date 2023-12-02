RSpec.describe Foobara::Namespace, :focus do
  let(:namespace_name) { "SomeNamespace" }
  let(:namespace) { described_class.new(namespace_name) }
  let(:scoped_object) { Object.new }
  let(:scoped_name) { "scoped_name" }

  before do
    scoped_object.extend(Foobara::Scoped)
    scoped_object.scoped_name = scoped_name
  end

  describe "#register" do
    it "registers the object and it can be found again" do
      namespace.register(scoped_object)

      [
        scoped_object.scoped_name,
        scoped_object.scoped_short_name,
        scoped_object.scoped_full_name,
        scoped_object.scoped_path,
        scoped_object.scoped_short_path,
        scoped_object.scoped_full_path
      ].each do |key|
        expect(namespace.lookup(key)).to be(scoped_object)
        expect(namespace.lookup!(key)).to be(scoped_object)
      end
    end
  end
end
