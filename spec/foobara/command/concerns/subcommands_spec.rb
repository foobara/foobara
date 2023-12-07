RSpec.describe Foobara::Command::Concerns::Subcommands do
  let(:command_class) {
    dep = subcommand_class

    stub_class(:RunSomeCommand, Foobara::Command) do
      inputs should_fail: :integer

      depends_on(dep)

      def execute
        run_subcommand!(RunSomeSubcommand, should_fail:)
      end
    end
  }

  let(:subcommand_class) {
    stub_class(:RunSomeSubcommand, Foobara::Command) do
      Foobara::Util.make_class "RunSomeSubcommand::ItFailedError", Foobara::RuntimeError do
        class << self
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
    end
  }

  describe "depends_on?" do
    context "when command registered via #depends_on" do
      it "is true" do
        expect(command_class.depends_on?(subcommand_class)).to be(true)
      end

      context "when checking by name" do
        it "is true" do
          expect(command_class.depends_on?("RunSomeSubcommand")).to be(true)
        end
      end
    end

    context "when command not registered via #depends_on" do
      it "is false" do
        expect(command_class.depends_on?(Object)).to be(false)
      end
    end
  end

  describe ".error_context_type_map" do
    let(:error_context_type_map) { command_class.error_context_type_map }

    it "contains subcommand error information" do
      expect(error_context_type_map).to eq(
        "data.cannot_cast" => Foobara::Value::Processor::Casting::CannotCastError,
        "data.unexpected_attributes" =>
          Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError,
        "data.should_fail.cannot_cast" => Foobara::Value::Processor::Casting::CannotCastError,
        "run_some_subcommand>data.cannot_cast" => Foobara::Value::Processor::Casting::CannotCastError,
        "run_some_subcommand>data.unexpected_attributes" =>
          Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError,
        "run_some_subcommand>data.should_fail.cannot_cast" => Foobara::Value::Processor::Casting::CannotCastError,
        "run_some_subcommand>runtime.it_failed" => RunSomeSubcommand::ItFailedError
      )
    end
  end

  describe ".errors_type_declaration" do
    it "contains error metadata" do
      expect(command_class.errors_type_declaration).to eq(
        "data.cannot_cast" => {
          key: "data.cannot_cast",
          path: [],
          runtime_path: [],
          category: :data,
          symbol: :cannot_cast,
          is_fatal: true,
          context_type_declaration: {
            type: :attributes,
            element_type_declarations: {
              cast_to: { type: :duck }, value: { type: :duck },
              attribute_name: { type: :symbol }
            }
          }
        },
        "data.unexpected_attributes" => {
          key: "data.unexpected_attributes",
          path: [],
          runtime_path: [],
          category: :data,
          symbol: :unexpected_attributes,
          is_fatal: true,
          context_type_declaration: {
            type: :attributes,
            element_type_declarations: {
              unexpected_attributes: { type: :array,
                                       element_type_declaration: { type: :symbol } },
              allowed_attributes: { type: :array,
                                    element_type_declaration: { type: :symbol } }
            }
          }
        },
        "data.should_fail.cannot_cast" => {
          key: "data.should_fail.cannot_cast",
          path: [:should_fail],
          runtime_path: [],
          category: :data,
          symbol: :cannot_cast,
          is_fatal: true,
          context_type_declaration: {
            type: :attributes,
            element_type_declarations: {
              cast_to: { type: :duck }, value: { type: :duck },
              attribute_name: { type: :symbol }
            }
          }
        },
        "run_some_subcommand>data.cannot_cast" => {
          key: "run_some_subcommand>data.cannot_cast",
          path: [],
          runtime_path: [:run_some_subcommand],
          category: :data,
          symbol: :cannot_cast,
          is_fatal: true,
          context_type_declaration: {
            type: :attributes,
            element_type_declarations: {
              cast_to: { type: :duck }, value: { type: :duck },
              attribute_name: { type: :symbol }
            }
          }
        },
        "run_some_subcommand>data.unexpected_attributes" => {
          key: "run_some_subcommand>data.unexpected_attributes",
          path: [],
          runtime_path: [:run_some_subcommand],
          category: :data,
          symbol: :unexpected_attributes,
          is_fatal: true,
          context_type_declaration: {
            type: :attributes,
            element_type_declarations: {
              unexpected_attributes: { type: :array,
                                       element_type_declaration: { type: :symbol } },
              allowed_attributes: { type: :array,
                                    element_type_declaration: { type: :symbol } }
            }
          }
        },
        "run_some_subcommand>data.should_fail.cannot_cast" => {
          key: "run_some_subcommand>data.should_fail.cannot_cast",
          path: [:should_fail],
          runtime_path: [:run_some_subcommand],
          category: :data,
          symbol: :cannot_cast,
          is_fatal: true,
          context_type_declaration: {
            type: :attributes,
            element_type_declarations: {
              cast_to: { type: :duck }, value: { type: :duck },
              attribute_name: { type: :symbol }
            }
          }
        },
        "run_some_subcommand>runtime.it_failed" => {
          key: "run_some_subcommand>runtime.it_failed",
          path: [],
          runtime_path: [:run_some_subcommand],
          category: :runtime,
          symbol: :it_failed,
          is_fatal: true,
          context_type_declaration: {
            type: :attributes,
            element_type_declarations: {
              foo: { type: :integer }
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

        expect(error.to_h).to eq(
          key: "run_some_subcommand>runtime.it_failed",
          path: [],
          runtime_path: [:run_some_subcommand],
          category: :runtime,
          is_fatal: true,
          symbol: :it_failed,
          message: "It failed!",
          context: { foo: 10 }
        )

        key = Foobara::ErrorKey.parse(error.key)

        expect(key.path).to eq([])
        expect(key.runtime_path).to eq([:run_some_subcommand])
        expect(key.category).to eq(:runtime)
        expect(key.symbol).to eq(:it_failed)
      end
    end
  end
end
