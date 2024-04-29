RSpec.describe Foobara::Command::Concerns::DomainMappers do
  after do
    Foobara.reset_alls
  end

  describe "#run_mapped_subcommand!" do
    let(:domain) do
      stub_module("SomeDomain") do
        foobara_domain!
      end
    end
    let(:command_class) do
      subcommand_class
      stub_class("SomeDomain::SomeCommand", Foobara::Command) do
        depends_on SomeDomain::SomeSubcommand

        def execute
          subcommand_inputs1 = domain_map("bar", to: SomeDomain::SomeSubcommand, from: :string, strict: true)
          subcommand_inputs2 = run_mapped_subcommand!(SomeDomain::SomeSubcommand, "bar")

          raise "wtf" unless subcommand_inputs1 == subcommand_inputs2

          subcommand_inputs1
        end
      end
    end

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

    let(:result_domain_mapper) do
      subcommand_class
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

    let(:command) { command_class.new }
    let(:outcome) { command.run }
    let(:result) { outcome.result }

    it "maps the inputs" do
      domain_mapper
      expect(outcome).to be_success
      expect(result).to eq(foo: "bar")
    end
  end
end
