RSpec.describe Foobara::Command::Concerns::Subcommands do
  let(:command_class) {
    Class.new(Foobara::Command) do
      input_schema should_fail: :integer

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
      input_schema should_fail: :integer

      possible_error(:it_failed, foo: :integer)

      def execute
        # TODO: add boolean input type as well as symbol and string
        if should_fail == 1
          add_runtime_error(
            symbol: :it_failed,
            message: "It failed!",
            context: { foo: 10 }
          )
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
    it "contains subcommand error information" do
      expect(command_class.error_context_schema_map).to eq(
        input: {
          should_fail: {
            cannot_cast: {
              cast_to: :integer,
              value: :duck
            }
          }
        },
        runtime: {
          could_not_run_some_subcommand: {
            input: {
              should_fail: {
                cannot_cast: {
                  cast_to: :integer,
                  value: :duck
                }
              }
            },
            runtime: {
              it_failed: {
                foo: :integer
              }
            }
          }
        }
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
        expect(error.symbol).to eq(:could_not_run_some_subcommand)
        expect(error.message).to eq("Failed to execute RunSomeSubcommand")
        expect(error.context).to eq(
          it_failed: {
            type: :runtime,
            symbol: :it_failed,
            message: "It failed!",
            context: { foo: 10 }
          }
        )
      end
    end
  end
end
