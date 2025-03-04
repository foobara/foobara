RSpec.describe Foobara::StateMachine do
  let(:state_machine_class) do
    stub_class "SomeStateMachine", described_class
    SomeStateMachine.set_transition_map(transition_map)
    SomeStateMachine
  end

  let(:transition_map) do
    {
      unexecuted: {
        start: :running
      },
      running: {
        fail: :failed,
        succeed: :succeeded,
        reset: :unexecuted
      }
    }
  end

  context "when embedded in another class and utilizing its target_attribute feature" do
    let(:some_class) do
      state_machine_class

      stub_class("SomeClass") do
        attr_accessor :state

        def state_machine
          @state_machine ||= SomeStateMachine.new(owner: self, target_attribute: :state)
        end
      end
    end

    it "reads/writes to the owner's state attribute" do
      some_object = some_class.new

      expect(some_object.state).to be_nil
      expect(some_object.state_machine.owner).to eq(some_object)
      expect(some_object.state_machine.target_attribute).to eq(:state)
      expect(some_object.state_machine.current_state).to eq(:unexecuted)
      some_object.state_machine.start!
      expect(some_object.state).to eq(:running)
      expect(some_object.state_machine.current_state).to eq(:running)
    end
  end
end
