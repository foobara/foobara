RSpec.describe Foobara::Command::Concerns::Subcommands do
  let(:command_class) {
    Class.new(Foobara::Command) do
      inputs should_fail: :integer

      depends_on(RunSomeSubcommand)

      def execute
        run_subcommand!(RunSomeSubcommand, should_fail:)
      end

      class << self
        def name
          "RunSomeCommand"
        end
      end
    end
  }

  let(:subcommand_class) {
    Class.new(Foobara::Command) do
      # rubocop:disable RSpec/LeakyConstantDeclaration
      self::ItFailedError = Class.new(Foobara::Command::RuntimeCommandError) do
        # rubocop:enable RSpec/LeakyConstantDeclaration
        class << self
          def name
            "RunSomeSubcommand::ItFailedError"
          end

          def context_type_declaration
            { foo: :integer }
          end
        end
      end

      inputs should_fail: :integer

      possible_error(self::ItFailedError)

      def execute
        # TODO: add boolean input type as well as symbol and string
        if should_fail == 1
          add_runtime_error(self.class::ItFailedError.new(context: { foo: 10 }, message: "It failed!"))
        end

        100
      end

      class << self
        def name
          "RunSomeSubcommand"
        end
      end
    end
  }

  before do
    stub_const("RunSomeSubcommand", subcommand_class)
  end

  describe ".error_context_type_map" do
    let(:error_context_type_map) { command_class.error_context_type_map }

    it "contains subcommand error information" do
      expect(error_context_type_map).to eq(
        "data.cannot_cast" => Foobara::Value::Processor::Casting::CannotCastError,
        "data.unexpected_attributes" =>
            Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError,
        "data.should_fail.cannot_cast" => Foobara::Value::Processor::Casting::CannotCastError,
        "run_some_subcommand:data.cannot_cast" => Foobara::Value::Processor::Casting::CannotCastError,
        "run_some_subcommand:data.unexpected_attributes" =>
            Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError,
        "run_some_subcommand:data.should_fail.cannot_cast" =>
            Foobara::Value::Processor::Casting::CannotCastError,
        "run_some_subcommand:runtime.it_failed" => RunSomeSubcommand::ItFailedError
      )
    end
  end

  describe "#run_subcommand" do
    let(:command) { command_class.new(should_fail:) }
    let(:outcome) { command.run }
    let(:result) { outcome.result }
    let(:errors) { outcome.errors }

    context "when it succeeds" do
      let(:should_fail) { 0 }

      it "is success" do
        expect(outcome).to be_success
        expect(result).to eq(100)
      end
    end

    context "when it fails due to runtime error" do
      let(:should_fail) { 1 }

      it "is not success" do
        expect(outcome).to_not be_success
        expect(errors.length).to eq(1)
        error = errors.first

        expect(error.to_h).to eq(
          key: "run_some_subcommand:runtime.it_failed",
          path: [],
          runtime_path: [:run_some_subcommand],
          category: :runtime,
          symbol: :it_failed,
          message: "It failed!",
          context: { foo: 10 }
        )

        key = Foobara::Error.parse_key(error.key)

        expect(key.path).to eq([])
        expect(key.runtime_path).to eq([:run_some_subcommand])
        expect(key.category).to eq(:runtime)
        expect(key.symbol).to eq(:it_failed)
      end
    end
  end
end
