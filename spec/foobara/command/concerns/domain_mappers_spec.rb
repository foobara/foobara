RSpec.describe Foobara::CommandPatternImplementation::Concerns::DomainMappers do
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
    mappers = domain_mappers

    stub_class("SomeDomain::SomeCommand", Foobara::Command) do
      depends_on SomeDomain::SomeSubcommand, *mappers

      result rtype

      def execute
        run_mapped_subcommand!(SomeDomain::SomeSubcommand, "bar", result_type)
      end
    end
  end
  let(:domain_mappers) do
    [
      SomeDomain::DomainMappers::SomeDomainMapper
    ]
  end

  let(:result_type) { :associative_array }

  let(:subcommand_class) do
    domain
    include_result = include_result_type
    stub_class("SomeDomain::SomeSubcommand", Foobara::Command) do
      inputs foo: :string
      if include_result
        result foo: :string
      end

      def execute
        inputs
      end
    end
  end
  let(:include_result_type) { true }

  let(:domain_mapper) do
    subcommand_class
    stub_module("SomeDomain::DomainMappers")
    stub_class("SomeDomain::DomainMappers::SomeDomainMapper", Foobara::DomainMapper) do
      from :string, :allow_nil
      to SomeDomain::SomeSubcommand

      def map
        { foo: from }
      end
    end
  end

  let(:irrelevant_domain_mapper) do
    subcommand_class
    domain_mapper
    stub_module("SomeDomain::DomainMappers")
    stub_class("SomeDomain::DomainMappers::IrrelevantDomainMapper", Foobara::DomainMapper) do
      from :integer
      to :integer
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
      mapped_value = domain_mapper.map("bar").result
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
        mappers = domain_mappers

        stub_class("SomeDomain::SomeCommand", Foobara::Command) do
          depends_on SomeDomain::SomeSubcommand, *mappers

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

      context "when forgetting to depend on the mapper" do
        let(:domain_mappers) { [irrelevant_domain_mapper] }

        it "raises" do
          expect {
            command.run
          }.to raise_error(
            Foobara::CommandPatternImplementation::Concerns::DomainMappers::ForgotToDependOnDomainMapperError
          )
        end
      end
    end

    context "when there's a result mapper" do
      before do
        result_domain_mapper
      end

      let(:domain_mappers) do
        [
          SomeDomain::DomainMappers::SomeDomainMapper,
          SomeDomain::DomainMappers::SomeResultDomainMapper
        ]
      end

      let(:result_domain_mapper) do
        subcommand_class
        domain_mapper
        stub_module("SomeDomain::DomainMappers")
        stub_class("SomeDomain::DomainMappers::SomeResultDomainMapper", Foobara::DomainMapper) do
          possible_error :some_error, context: { foo: :string }, message: "kaboom!"

          from SomeDomain::DomainMappers::SomeDomainMapper.to_type
          to :string

          def map
            JSON.generate(from)
          end
        end
      end

      let(:result_type) { :string }

      it "maps the inputs and the results" do
        mapper = domain_mapper.domain.lookup_matching_domain_mapper! to: :string
        expect(mapper).to be(SomeDomain::DomainMappers::SomeResultDomainMapper)
        expect(outcome).to be_success
        expect(result).to eq("{\"foo\":\"bar\"}")
      end

      it "contains the mapper's errors in the depending command's possible errors" do
        possible_error_keys = command_class.possible_errors.map(&:key).map(&:to_s)
        expect(possible_error_keys).to include(
          "some_domain::domain_mappers::some_result_domain_mapper>runtime.some_error"
        )
      end

      context "when the subcommand has no result type" do
        let(:include_result_type) { false }

        it "maps the inputs and the results" do
          expect(outcome).to be_success
          expect(result).to eq("{\"foo\":\"bar\"}")
        end
      end

      context "when forgetting to depend on the mapper" do
        let(:domain_mappers) { [irrelevant_domain_mapper] }

        it "raises" do
          result_domain_mapper
          expect {
            command.run
          }.to raise_error(
            Foobara::CommandPatternImplementation::Concerns::DomainMappers::ForgotToDependOnDomainMapperError
          )
        end
      end
    end

    context "when only there's a result mapper" do
      let(:command_class) do
        rtype = result_type
        subcommand_class
        mappers = domain_mappers

        stub_class("SomeDomain::SomeCommand", Foobara::Command) do
          depends_on SomeDomain::SomeSubcommand, *mappers

          result rtype

          def execute
            run_mapped_subcommand!(SomeDomain::SomeSubcommand, { foo: "bar" }, result_type)
          end
        end
      end

      let(:domain_mappers) do
        [
          result_domain_mapper
        ]
      end

      let(:result_domain_mapper) do
        subcommand_class
        domain_mapper
        stub_module("SomeDomain::DomainMappers")
        stub_class("SomeDomain::DomainMappers::SomeResultDomainMapper", Foobara::DomainMapper) do
          from SomeDomain::DomainMappers::SomeDomainMapper.to_type
          to :string

          def map
            JSON.generate(from)
          end
        end
      end

      let(:result_type) { :string }

      it "maps the results" do
        mapper = command_class.foobara_domain.lookup_matching_domain_mapper! to: :string
        expect(mapper).to be(SomeDomain::DomainMappers::SomeResultDomainMapper)
        expect(outcome).to be_success
        expect(result).to eq("{\"foo\":\"bar\"}")
      end

      context "when forgetting to depend on the mapper" do
        let(:domain_mappers) { [irrelevant_domain_mapper] }

        it "raises" do
          result_domain_mapper
          expect {
            command.run
          }.to raise_error(
            Foobara::CommandPatternImplementation::Concerns::DomainMappers::ForgotToDependOnDomainMapperError
          )
        end
      end

      context "when no mapper found" do
        let(:domain_mappers) { [] }

        let(:command_class) do
          rtype = result_type
          subcommand_class
          mappers = domain_mappers

          stub_class("SomeDomain::SomeCommand", Foobara::Command) do
            depends_on SomeDomain::SomeSubcommand, *mappers

            result rtype

            def execute
              run_mapped_subcommand!(SomeDomain::SomeSubcommand, { foo: "bar" }, :integer)
            end
          end
        end

        it "raises" do
          expect {
            command.run
          }.to raise_error(Foobara::CommandPatternImplementation::Concerns::DomainMappers::NoDomainMapperFoundError)
        end
      end
    end

    context "when domain mappers are ambiguous" do
      let(:domain_mapper_more_specific) do
        subcommand_class
        stub_module("SomeDomain::DomainMappers")
        stub_class("SomeDomain::DomainMappers::MoreSpecific", Foobara::DomainMapper) do
          from :integer
          to :integer

          def map
            100
          end
        end
      end

      let(:domain_mapper_less_specific) do
        subcommand_class
        stub_module("SomeDomain::DomainMappers")
        stub_class("SomeDomain::DomainMappers::LessSpecific", Foobara::DomainMapper) do
          from :string
          to :integer
        end
      end

      let(:domain_mappers) { [domain_mapper_more_specific, domain_mapper_less_specific] }

      it "chooses the more specific one" do
        expect(command.domain_map!(-1, from: :integer)).to eq(100)
      end
    end
  end
end
