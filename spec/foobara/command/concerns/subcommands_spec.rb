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

  describe ".context_error_map" do
    # TODO: encapsulate sub command errors into a simpler construct?
    it "contains subcommand error information" do
      map = command_class.error_context_type_map

      runtime = map[:runtime]

      map = map.except(:runtime)

      expect(map).to eq(
        input: {
          [] => {
            cannot_cast: Foobara::Value::Processor::Casting::CannotCastError,
            unexpected_attribute:
              Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributeError
          },
          [:should_fail] => { cannot_cast: Foobara::Value::Processor::Casting::CannotCastError }
        }
      )
      expect(runtime.keys).to eq([:could_not_run_some_subcommand])
      expect(runtime.values.first.superclass).to be(described_class::FailedToExecuteSubcommand)
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
        expect(error.symbol).to eq(:could_not_run_some_subcommand)
        expect(error.message).to eq("Failed to execute RunSomeSubcommand")
        expect(error.context[:runtime]).to eq(
          it_failed: {
            symbol: :it_failed,
            message: "It failed!",
            context: { foo: 10 }
          }
        )
      end
    end
  end
end
