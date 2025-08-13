RSpec.describe Foobara::DomainMapper do
  after do
    Foobara.reset_alls
  end

  let(:domain_a) do
    stub_module("DomainA") do
      foobara_domain!
    end
  end

  let(:some_class) do
    stub_class("SomeClass")
  end
  let(:some_other_class) do
    stub_class("SomeOtherClass")
  end

  let(:domain_mapper) do
    domain_a
    # TODO: implement a stub_module_p
    stub_module("DomainA::DomainMappers")
    stub_module("DomainA::DomainMappers::DomainB")
    stub_class("DomainA::DomainMappers::DomainB::UserB", described_class) do
      from do
        foo :integer
        bar :string
      end
      to SomeClass

      def map
        SomeClass.new
      end
    end
  end

  before do
    some_class
    some_other_class
    domain_mapper
  end

  describe ".to_type" do
    context "when to is a class" do
      it "returns a duck that matches that class" do
        expect(domain_mapper.to_type.declaration_data).to eq(instance_of: "SomeClass", type: :duck)
      end
    end
  end

  describe "#applicable?" do
    context "when to matches class" do
      it "is true" do
        expect(domain_mapper.applicable?({ foo: 1, bar: "baz" }, SomeClass)).to be(true)
      end
    end

    context "when it doesn't match the class" do
      it "is false" do
        expect(domain_mapper).to_not be_applicable(1, SomeOtherClass)
      end
    end
  end

  describe "#map!" do
    it "maps it" do
      domain_mapper
      mapped_value = domain_mapper.map!(foo: 1, bar: "baz")
      expect(mapped_value).to be_a(SomeClass)
    end
  end

  describe "#foobara_domain_map!" do
    it "maps it" do
      mapped_value = domain_a.foobara_domain_map!(foo: 1, bar: "baz")
      expect(mapped_value).to be_a(SomeClass)
    end
  end
end
