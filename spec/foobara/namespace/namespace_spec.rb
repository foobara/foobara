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

      expect(scoped_object.namespace).to be(namespace)

      keys = [
        "scoped_name",
        ["scoped_name"]
      ]

      keys.each do |key|
        expect(namespace.lookup(key)).to be(scoped_object)
        expect(namespace.lookup!(key)).to be(scoped_object)
      end
    end

    context "with prefixes" do
      let(:scoped_name) { "some::prefix::scoped_name" }

      it "registers the object and it can be found again" do
        namespace.register(scoped_object)

        keys = [
          scoped_object.scoped_name,
          scoped_object.scoped_short_name,
          scoped_object.scoped_full_name,
          scoped_object.scoped_path,
          scoped_object.scoped_short_path,
          scoped_object.scoped_full_path
        ].uniq

        puts keys.inspect

        keys = [
          "some::prefix::scoped_name",
          "scoped_name",
          %w[some prefix scoped_name],
          ["scoped_name"]
        ]

        keys.each do |key|
          expect(namespace.lookup(key)).to be(scoped_object)
          expect(namespace.lookup!(key)).to be(scoped_object)
        end
      end
    end
  end
end
