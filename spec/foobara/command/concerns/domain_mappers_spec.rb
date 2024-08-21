RSpec.describe Foobara::Command::Concerns::DomainMappers do
  after do
    Foobara.reset_alls
  end

  let(:domain) do
    stub_module("SomeDomain") do
      foobara_domain!
    end
  end
  let(:command_class) do
    rtype = result_type
    subcommand_class
    stub_class("SomeDomain::SomeCommand", Foobara::Command) do
      depends_on SomeDomain::SomeSubcommand

      result rtype

      def execute
        run_mapped_subcommand!(SomeDomain::SomeSubcommand, result_type, "bar")
      end
    end
  end
  let(:result_type) { :associative_array }

  let(:subcommand_class) do
    domain
    stub_class("SomeDomain::SomeSubcommand", Foobara::Command) do
      inputs foo: :string

      def execute
        inputs
      end
    end
  end

  let(:domain_mapper) do
    subcommand_class
    stub_module("SomeDomain::DomainMappers")
    stub_class("SomeDomain::DomainMappers::SomeDomainMapper", Foobara::DomainMapper) do
      from :string
      to SomeDomain::SomeSubcommand

      # TODO: pass from_value in instead for improved readability
      def map(from_value)
        { foo: from_value }
      end
    end
  end

  let(:command) { command_class.new }
  let(:outcome) { command.run }
  let(:result) { outcome.result }

  describe "#domain_map" do
    it "maps the value" do
      domain_mapper
      mapped_value = command.domain_map("bar")
      expect(mapped_value).to eq(foo: "bar")
    end
  end

  describe "#run_mapped_subcommand!" do
    before do
      domain_mapper
    end

    context "when there's no result mapper" do
      let(:command_class) do
        rtype = result_type
        subcommand_class
        stub_class("SomeDomain::SomeCommand", Foobara::Command) do
          depends_on SomeDomain::SomeSubcommand

          result rtype

          def execute
            run_mapped_subcommand!(SomeDomain::SomeSubcommand, "bar")
          end
        end
      end

      it "maps the inputs" do
        expect(outcome).to be_success
        expect(result).to eq(foo: "bar")
      end
    end

    context "when there's a result mapper" do
      before do
        result_domain_mapper
      end

      let(:result_domain_mapper) do
        subcommand_class
        domain_mapper
        stub_module("SomeDomain::DomainMappers")
        stub_class("SomeDomain::DomainMappers::SomeResultDomainMapper", Foobara::DomainMapper) do
          from SomeDomain::DomainMappers::SomeDomainMapper.to_type
          to :string

          # TODO: pass from_value in instead for improved readability
          def map(from_value)
            JSON.generate(from_value)
          end
        end
      end

      let(:result_type) { :string }

      it "maps the inputs and the results" do
        expect(outcome).to be_success
        expect(result).to eq("{\"foo\":\"bar\"}")
      end
    end
  end
end
