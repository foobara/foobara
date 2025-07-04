RSpec.describe Foobara::StateMachine do
  describe ".set_transition_map" do
    subject { state_machine_class }

    let(:state_machine_class) do
      Class.new(described_class).tap do |klass|
        klass.set_transition_map(
          transition_map,
          states:,
          initial_state:,
          terminal_states:,
          transitions:
        )
      end
    end

    let(:state_machine) {
      state_machine_class.new
    }

    let(:states) { nil }
    let(:initial_state) { nil }
    let(:terminal_states) { nil }
    let(:transitions) { nil }

    let(:transition_map) do
      {
        unexecuted: {
          start: :running
        },
        running: {
          fail: :failed,
          succeed: :succeeded
        }
      }
    end

    context "with only the transition map" do
      its(:states) { is_expected.to eq([:unexecuted, :running, :failed, :succeeded]) }
      its(:non_terminal_states) { is_expected.to eq([:unexecuted, :running]) }
      its(:terminal_states) { is_expected.to eq([:failed, :succeeded]) }
      its(:initial_state) { is_expected.to eq(:unexecuted) }
      its(:transitions) { is_expected.to eq([:start, :fail, :succeed]) }

      its(:transition_map) {
        is_expected.to eq(
          running: { fail: :failed, succeed: :succeeded },
          unexecuted: { start: :running }
        )
      }

      context "with sugary transition map" do
        let(:transition_map) do
          {
            unexecuted: {
              start: :running
            },
            running: {
              succeed: :succeeded
            },
            [:unexecuted, :running] => {
              fail: :failed
            }
          }
        end

        its(:states) { is_expected.to eq([:unexecuted, :running, :failed, :succeeded]) }
        its(:non_terminal_states) { is_expected.to eq([:unexecuted, :running]) }
        its(:terminal_states) { is_expected.to eq([:failed, :succeeded]) }
        its(:initial_state) { is_expected.to eq(:unexecuted) }
        its(:transitions) { is_expected.to eq([:start, :fail, :succeed]) }

        describe "#state" do
          it "is the expected enum" do
            expect(state_machine_class.state.all_values).to match_array(state_machine_class.states)
            expect(state_machine_class.state.FAILED).to eq(:failed)
          end
        end

        describe "#transition" do
          it "is the expected enum" do
            expect(state_machine_class.transition.all_values).to match_array(state_machine_class.transitions)
            expect(state_machine_class.transition.FAIL).to eq(:fail)
          end
        end

        describe "#perform_transition!" do
          subject { state_machine.perform_transition!(transition) }

          context "when valid transition" do
            let(:transition) { :start }

            it { is_expected_to change(state_machine, :current_state).from(:unexecuted).to(:running) }
          end

          context "when invalid transition" do
            let(:transition) { :bad_transition }

            # TODO: use two different exceptions to avoid checking the error message
            it { is_expected_to_raise(Foobara::StateMachine::InvalidTransition, /Expected one of/) }
          end

          context "when in terminal state" do
            let(:transition) { :fail }

            before do
              state_machine.start!
              state_machine.succeed!
            end

            it "explodes" do
              expect(state_machine).to be_in_terminal_state
              expect(state_machine.allowed_transitions).to be_empty

              expect {
                state_machine.fail!
              }.to raise_error(Foobara::StateMachine::InvalidTransition, /is a terminal state/)
            end
          end
        end

        describe "dynamically created can predicates" do
          it "creates can predicates from the transitions" do
            expect(state_machine.can_start?).to be(true)
            expect(state_machine.can_succeed?).to be(false)
          end
        end

        describe "#allowed_transitions" do
          it "is the expected allowed transitions" do
            expect(state_machine.allowed_transitions).to eq([:start, :fail])
          end
        end

        its(:transition_map) {
          is_expected.to eq(
            running: { fail: :failed, succeed: :succeeded },
            unexecuted: { fail: :failed, start: :running }
          )
        }
      end
    end

    context "with states" do
      context "with valid states" do
        let(:states) { [:unexecuted, :running, :failed, :succeeded] }

        its(:states) { is_expected.to eq([:unexecuted, :running, :failed, :succeeded]) }
      end

      context "with extra states" do
        let(:states) { [:running, :failed, :succeeded] }

        it { is_expected_to_raise(Foobara::StateMachine::ExtraStates) }
      end

      context "with missing states" do
        let(:states) { [:unexecuted, :running, :failed, :succeeded, :extra] }

        it { is_expected_to_raise(Foobara::StateMachine::MissingStates) }
      end
    end

    context "with terminal states" do
      context "with valid states that counts a state with as transition (running)" do
        let(:terminal_states) { [:running, :failed, :succeeded] }

        its(:terminal_states) { is_expected.to eq([:running, :failed, :succeeded]) }
      end

      context "with extra terminal_states" do
        let(:terminal_states) { [:succeeded] }

        it { is_expected_to_raise(Foobara::StateMachine::UnexpectedTerminalStates) }
      end

      context "with missing terminal_states" do
        let(:terminal_states) { [:unexecuted, :running, :failed, :succeeded, :extra] }

        it { is_expected_to_raise(Foobara::StateMachine::MissingTerminalStates) }
      end
    end

    context "with initial_state" do
      context "with valid initial state that isn't the default" do
        let(:initial_state) { :running }

        its(:initial_state) { is_expected.to eq(:running) }
      end

      context "with invalid initial state" do
        let(:initial_state) { :invalid }

        it { is_expected_to_raise(Foobara::StateMachine::BadInitialState) }
      end
    end

    context "with transitions" do
      context "with valid transitions" do
        let(:transitions) { [:start, :fail, :succeed] }

        its(:transitions) { is_expected.to eq([:start, :fail, :succeed]) }
      end

      context "with extra transitions" do
        let(:transitions) { [:start, :succeed] }

        it { is_expected_to_raise(Foobara::StateMachine::ExtraTransitions) }
      end

      context "with missing transitions" do
        let(:transitions) { [:start, :fail, :succeed, :extra] }

        it { is_expected_to_raise(Foobara::StateMachine::MissingTransitions) }
      end
    end

    describe ".states_that_can_perform" do
      it "returns the expected states allowed to perform the given transition" do
        expect(state_machine_class.states_that_can_perform(:start)).to eq([:unexecuted])
      end
    end
  end
end
