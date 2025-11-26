RSpec.describe "Foobara::Concern" do
  context "when inheriting through another concern" do
    let(:root_concern) do
      stub_module "SomeModule" do
        include Foobara::Concern

        inherited_overridable_class_attr_accessor :some_delegated_value
        inherited_overridable_class_attr_accessor :some_delegated_value2

        on_include do
          singleton_class.define_method :name_under do
            Foobara::Util.underscore(name)
          end
        end
      end

      stub_module "SomeModule::ClassMethods" do
        attr_accessor :some_non_delegated_value

        def foo?
          true
        end
      end

      SomeModule
    end

    let(:sub_concern) do
      r = root_concern

      stub_module "SubConcern" do
        include Foobara::Concern
        include r
      end
    end

    let(:klass) do
      c = sub_concern

      stub_class :SomeClass do
        include c
      end
    end

    it "passes class methods and effects of on_include through" do
      expect(klass.singleton_class.ancestors.map(&:name)).to include("SubConcern::ClassMethods")
      expect(klass.foo?).to be(true)
      expect(klass.name_under).to eq("some_class")
      klass.some_non_delegated_value = "hi!"
      expect(klass.some_non_delegated_value).to eq("hi!")
    end

    context "when subclassing a class that included a concern with class methods" do
      let(:subclass) do
        stub_class :Subclass, klass
      end

      it "sets up the subclass and its instances correctly" do
        expect(klass.singleton_class.ancestors.map(&:name)).to include("SubConcern::ClassMethods")
        expect(klass.foo?).to be(true)
        expect(klass.name_under).to eq("some_class")

        klass.some_non_delegated_value = "foo"
        expect(klass.some_non_delegated_value).to eq("foo")
        expect(subclass.some_non_delegated_value).to be_nil
        subclass.some_non_delegated_value = "bar"
        expect(subclass.some_non_delegated_value).to eq("bar")
        expect(klass.some_non_delegated_value).to eq("foo")
      end
    end

    context "when there are delegated class methods" do
      let(:class_a1) do
        stub_class(:ClassA1).tap do |klass|
          klass.include root_concern
        end
      end

      let(:class_a2) do
        stub_class(:ClassA2, ClassA1)
      end

      let(:class_a3) do
        stub_class(:ClassA3, ClassA2)
      end

      let(:class_b1) do
        stub_class(:ClassB1).tap do |klass|
          klass.include root_concern
        end
      end

      let(:all_classes) do
        [class_a1, class_a2, class_a3, class_b1]
      end

      it "shares state in inheritance chains starting at its include." do
        all_classes.each do |klass|
          expect(klass.some_delegated_value).to be_nil
        end

        class_a1.some_delegated_value = "foo"
        expect(class_a1.some_delegated_value).to eq("foo")
        expect(class_a2.some_delegated_value).to eq("foo")
        expect(class_a3.some_delegated_value).to eq("foo")
        expect(class_b1.some_delegated_value).to be_nil

        class_b1.some_delegated_value = "bar"
        expect(class_a1.some_delegated_value).to eq("foo")
        expect(class_a2.some_delegated_value).to eq("foo")
        expect(class_a3.some_delegated_value).to eq("foo")
        expect(class_b1.some_delegated_value).to eq("bar")

        class_a3.some_delegated_value = "baz"
        expect(class_a1.some_delegated_value).to eq("foo")
        expect(class_a2.some_delegated_value).to eq("foo")
        expect(class_a3.some_delegated_value).to eq("baz")
        expect(class_b1.some_delegated_value).to eq("bar")
      end
    end
  end
end
