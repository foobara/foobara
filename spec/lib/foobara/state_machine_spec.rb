RSpec.describe Foobara::StateMachine do
  describe ".new" do
    subject { state_machine }

    let(:state_machine) {
      described_class.new(
        transition_map,
        states:,
        initial_state:,
        terminal_states:,
        transitions:
      )
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
      its(:states) { is_expected.to eq(%i[unexecuted running failed succeeded]) }
      its(:non_terminal_states) { is_expected.to eq(%i[unexecuted running]) }
      its(:terminal_states) { is_expected.to eq(%i[failed succeeded]) }
      its(:initial_state) { is_expected.to eq(:unexecuted) }
      its(:transitions) { is_expected.to eq(%i[start fail succeed]) }

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
            %i[unexecuted running] => {
              fail: :failed
            }
          }
        end

        its(:states) { is_expected.to eq(%i[unexecuted running failed succeeded]) }
        its(:non_terminal_states) { is_expected.to eq(%i[unexecuted running]) }
        its(:terminal_states) { is_expected.to eq(%i[failed succeeded]) }
        its(:initial_state) { is_expected.to eq(:unexecuted) }
        its(:transitions) { is_expected.to eq(%i[start fail succeed]) }

        describe "#state" do
          it "is the expected enum" do
            expect(state_machine.state.all_values).to match_array(state_machine.states)
            expect(state_machine.state.FAILED).to eq(:failed)
          end
        end

        describe "#transition" do
          it "is the expected enum" do
            expect(state_machine.transition.all_values).to match_array(state_machine.transitions)
            expect(state_machine.transition.FAIL).to eq(:fail)
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
        let(:states) { %i[unexecuted running failed succeeded] }

        its(:states) { is_expected.to eq(%i[unexecuted running failed succeeded]) }
      end

      context "with extra states" do
        let(:states) { %i[running failed succeeded] }

        it { is_expected_to_raise(Foobara::StateMachine::ExtraStates) }
      end

      context "with missing states" do
        let(:states) { %i[unexecuted running failed succeeded extra] }

        it { is_expected_to_raise(Foobara::StateMachine::MissingStates) }
      end
    end

    context "with terminal states" do
      context "with valid states that counts a state with as transition (running)" do
        let(:terminal_states) { %i[running failed succeeded] }

        its(:terminal_states) { is_expected.to eq(%i[running failed succeeded]) }
      end

      context "with extra terminal_states" do
        let(:terminal_states) { %i[succeeded] }

        it { is_expected_to_raise(Foobara::StateMachine::UnexpectedTerminalStates) }
      end

      context "with missing terminal_states" do
        let(:terminal_states) { %i[unexecuted running failed succeeded extra] }

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
        let(:transitions) { %i[start fail succeed] }

        its(:transitions) { is_expected.to eq(%i[start fail succeed]) }
      end

      context "with extra transitions" do
        let(:transitions) { %i[start succeed] }

        it { is_expected_to_raise(Foobara::StateMachine::ExtraTransitions) }
      end

      context "with missing transitions" do
        let(:transitions) { %i[start fail succeed extra] }

        it { is_expected_to_raise(Foobara::StateMachine::MissingTransitions) }
      end
    end
  end
end
