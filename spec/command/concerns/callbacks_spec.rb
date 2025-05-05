RSpec.describe Foobara::CommandPatternImplementation::Concerns::Callbacks do
  after do
    Foobara.reset_alls
  end

  context "with simple command" do
    let(:command_class) {
      stub_class(:CommandClass, Foobara::Command) do
        inputs exponent: :integer,
               base: :integer

        attr_accessor :exponential

        def execute
          compute

          exponential
        end

        def compute
          self.exponential = 1

          exponent.times do
            self.exponential *= base
          end
        end
      end
    }
    let(:base) { 4 }
    let(:exponent) { 3 }
    let(:command) { command_class.new(base:, exponent:) }
    let(:state_machine) { command.state_machine }
    let(:called) { [] }

    after do
      command_class.remove_all_callbacks
    end

    describe ".run!" do
      let(:outcome) { command.run }
      let(:result) { outcome.result }

      context "when there are various instance callbacks" do
        before do
          @before_run_execute_called = false
          command.before_run_execute do |**args|
            expect(args[:command]).to be(command)
            @before_run_execute_called = true
          end
        end

        context "when success" do
          before do
            expect(outcome).to be_success
            expect(command).to be_success
          end

          it "runs callbacks" do
            expect(@before_run_execute_called).to be(true)
          end
        end
      end

      context "when there are various class callbacks" do
        before do
          @before_run_execute_called = false
          command_class.before_run_execute do |**args|
            expect(args[:command]).to be(command)
            @before_run_execute_called = true
          end
        end

        context "when success" do
          before do
            expect(outcome).to be_success
          end

          it "runs callbacks" do
            expect(@before_run_execute_called).to be(true)
          end
        end
      end

      context "when given a callback with no conditions" do
        before do
          command_class.around_any_transition do |transition:, **args, &do_it|
            expect(args[:command]).to be(command)

            do_it.call

            called << transition
          end
        end

        context "when success" do
          before do
            expect(outcome).to be_success
          end

          it "runs callbacks" do
            expect(called).to eq(
              [
                :open_transaction,
                :cast_and_validate_inputs,
                :load_records,
                :validate_records,
                :validate,
                :run_execute,
                :commit_transaction,
                :succeed
              ]
            )
          end
        end
      end

      context "when before any transition" do
        before do
          command_class.before_any_transition do |transition:, **_args|
            called << transition
          end
        end

        it "calls before callback for every transition" do
          expect(outcome).to be_success

          expect(called).to eq(
            [
              :open_transaction,
              :cast_and_validate_inputs,
              :load_records,
              :validate_records,
              :validate,
              :run_execute,
              :commit_transaction,
              :succeed
            ]
          )
        end
      end

      context "when around a specific transition" do
        before do
          command_class.around_validate_records do |transition:, **_args, &do_it|
            do_it.call

            called << transition
          end
        end

        it "calls around callback for that transition" do
          expect(outcome).to be_success

          expect(called).to eq([:validate_records])
        end
      end

      context "when error for any transition" do
        before do
          command_class.define_method :validate_records do
            raise "kaboom!"
          end
          command_class.error_any_transition do |error:, command:, state_machine:, from:, to:, transition:|
            called << { error:, command:, state_machine:, from:, to:, transition: }
          end
        end

        it "calls around callback for that transition" do
          expect {
            outcome
          }.to raise_error("kaboom!")

          expect(called.size).to eq(1)

          callback_data = called.first

          error = callback_data[:error]
          command = callback_data[:command]
          state_machine = callback_data[:state_machine]
          from = callback_data[:from]
          to = callback_data[:to]
          transition = callback_data[:transition]

          expect(error).to be_a(Foobara::Callback::Runner::UnexpectedErrorWhileRunningCallback)
          original_error = error.cause

          expect(original_error).to be_a(RuntimeError)
          expect(original_error.message).to eq("kaboom!")

          expect(state_machine).to be_a(Foobara::StateMachine)
          expect(command).to be_a(Foobara::Command)

          expect(from).to eq(:loaded_records)
          expect(transition).to eq(:validate_records)
          expect(to).to eq(:validated_records)
        end
      end
    end
  end

  describe ".subclass_defined_callbacks" do
    before do
      stub_class "CommandA", Foobara::Command
      stub_class "CommandB", CommandA
    end

    it "can pass them on to a subclass" do
      expect(Foobara::Command.all).to include(CommandB)
    end
  end
end
