RSpec.describe Foobara::Namespace::NamespaceHelpers do
  describe ".foobara_instances_are_namespaces!" do
    let(:instance) { klass.new(name) }

    let(:default_parent) { Foobara::Namespace.new("ParentNamespace") }
    let(:klass) do
      stub_class("SomeClass") do
        attr_reader :name

        def initialize(name)
          @name = name
          super
        end

        def scoped_path
          [name]
        end
      end
    end
    let(:autoregister) { true }
    let(:name) { "some_name" }

    before do
      klass.foobara_instances_are_namespaces!(default_parent:, autoregister:)
    end

    it "sets up the instance as expected" do
      expect(instance).to be_a(Foobara::Namespace::IsNamespace)
      expect(instance.foobara_parent_namespace).to eq(default_parent)
    end

    context "when inherited" do
      let(:subclass) { stub_class "SomeSubclass", klass }
      let(:instance) { subclass.new(name) }

      it "sets up the instance as expected" do
        expect(instance).to be_a(subclass)
        expect(instance).to be_a(Foobara::Namespace::IsNamespace)
        expect(instance.foobara_parent_namespace).to eq(default_parent)
      end
    end
  end
end
