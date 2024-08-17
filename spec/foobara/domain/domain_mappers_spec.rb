RSpec.describe "Domain Mappers" do
  after do
    Foobara.reset_alls
  end

  let(:domain_a) do
    other = domain_b
    stub_module("DomainA") do
      foobara_domain!

      foobara_depends_on other
    end
  end
  let(:from_value) do
    from_type.new(first_name: "foo", last_name: "bar")
  end
  let(:domain_b) do
    stub_module("DomainB") do
      foobara_domain!
    end
  end

  let(:from_type) do
    domain_b
    stub_class("DomainB::UserB", Foobara::Model) do
      attributes do
        first_name :string
        last_name :string
      end
    end
  end

  let(:to_type) do
    domain_a
    stub_class("DomainA::UserA", Foobara::Model) do
      attributes do
        name do
          first :string
          last :string
        end
      end
    end
  end

  let(:domain_mapper) do
    from_t = from_type
    to_t = to_type

    # TODO: implement a stub_module_p
    stub_module("DomainA::DomainMappers")
    stub_module("DomainA::DomainMappers::DomainB")
    stub_class("DomainA::DomainMappers::DomainB::UserB", Foobara::DomainMapper) do
      from from_t
      to to_t

      # TODO: pass from_value in instead for improved readability
      def map(from_value)
        {
          name: {
            first: from_value.first_name,
            last: from_value.last_name
          }
        }
      end
    end
  end

  before do
    domain_mapper
  end

  describe ".foobara_domain_map" do
    it "maps from one domain to the other" do
      to_value = domain_a.foobara_domain_map(from_value)
      expect(to_value).to be_a(to_type)
      expect(to_value.name[:first]).to eq("foo")
      expect(to_value.name[:last]).to eq("bar")
    end

    context "when can't find a mapper" do
      let(:from_value) { Object.new }

      it "is nil" do
        expect(domain_a.foobara_domain_map(from_value, from: :integer, strict: true)).to be_nil
      end
    end

    context "when not strict" do
      context "when from is wrong" do
        it "can still find it" do
          expect(
            domain_a.foobara_domain_map(from_value, to: Object.new, from: Object.new, strict: false)
          ).to be_a(to_type)
        end
      end
    end

    context "when there's multiple mappers" do
      let(:some_other_mapper) do
        # TODO: implement a stub_module_p
        stub_module("DomainA::DomainMappers")
        stub_class("DomainA::DomainMappers::SomeOtherMapper", Foobara::DomainMapper) do
          from :integer
          to :string
        end
      end

      before do
        some_other_mapper
      end

      context "when ambiguous" do
        it "raises" do
          expect {
            domain_a.foobara_domain_map(from_value, from: nil)
          }.to raise_error(Foobara::DomainMapper::Registry::AmbiguousDomainMapperError)
        end
      end
    end
  end

  describe ".foobara_domain_map!" do
    it "maps from one domain to the other" do
      to_value = domain_a.foobara_domain_map!(from_value)
      expect(to_value).to be_a(to_type)
      expect(to_value.name[:first]).to eq("foo")
      expect(to_value.name[:last]).to eq("bar")
    end

    context "when can't find the mapper" do
      let(:from_value) { Object.new }

      it "raises" do
        expect {
          domain_a.foobara_domain_map!(from_value, from: :integer, strict: true)
        }.to raise_error(Foobara::DomainMapper::NoDomainMapperFoundError)
      end
    end
  end
end
