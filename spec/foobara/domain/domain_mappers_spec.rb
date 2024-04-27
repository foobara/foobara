RSpec.describe "Domain Mappers" do
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
    from = from_type
    to = to_type

    # TODO: implement a stub_module_p
    stub_module("DomainA::DomainMappers")
    stub_module("DomainA::DomainMappers::DomainB")
    stub_class("DomainA::DomainMappers::DomainB::UserB", Foobara::DomainMapper) do
      from_type from
      to_type to

      # TODO: pass from_value in instead for improved readability
      def call
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
    it "maps from one domain to the other", :focus do
      to_value = domain_a.domain_map(from_value)
      expect(to_value).to be_a(to_type)
      expect(to_value.name[:first]).to eq("foo")
      expect(to_value.name[:last]).to eq("bar")
    end
  end
end
