RSpec.describe Foobara::StateMachine::Callbacks do
  subject { state_machine_class }

  let(:state_machine_class) do
    Foobara::StateMachine.for(transition_map)
  end

  let(:state_machine) { state_machine_class.new }

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

  describe "dynamic transition callback helpers" do
    # before after around error any
    # from
    # to
    # from to
    # tx from
    # tx to
    let(:calls) { [] }
    let(:from) { :unexecuted }
    let(:to) { :running }
    let(:transition) { :start }

    def set_callback(callback_name)
      record_call = ->(**_opts) { calls << callback_name }

      block = case callback_name
              when /^around_/
                ->(**_opts, &do_it) {
                  record_call.call
                  do_it.call
                }
              when /^error_/
                ->(_error) { record_call.call }
              else
                record_call
              end

      state_machine.send(callback_name, &block)
    end

    it "calls them all" do
      [:before, :around, :after, :error].each do |type|
        [
          "#{type}_any_transition",
          "#{type}_transition_from_#{from}",
          "#{type}_transition_to_#{to}",
          "#{type}_transition_from_#{from}_to_#{to}",
          "#{type}_#{transition}",
          "#{type}_#{transition}_from_#{from}",
          "#{type}_#{transition}_to_#{to}",
          "#{type}_#{transition}_from_#{from}_to_#{to}"
        ].each do |callback_name|
          set_callback(callback_name)
        end
      end

      state_machine.perform_transition!(transition)

      # 8 for each type but error type won't be called here
      expect(calls.size).to eq(24)

      expect(calls).to contain_exactly(
        "before_start_from_unexecuted_to_running",
        "before_transition_from_unexecuted_to_running",
        "before_start_from_unexecuted",
        "before_transition_from_unexecuted",
        "before_start_to_running",
        "before_transition_to_running",
        "before_start",
        "before_any_transition",
        "around_any_transition",
        "around_start",
        "around_transition_to_running",
        "around_start_to_running",
        "around_transition_from_unexecuted",
        "around_start_from_unexecuted",
        "around_transition_from_unexecuted_to_running",
        "around_start_from_unexecuted_to_running",
        "after_start_from_unexecuted_to_running",
        "after_transition_from_unexecuted_to_running",
        "after_start_from_unexecuted",
        "after_transition_from_unexecuted",
        "after_start_to_running",
        "after_transition_to_running",
        "after_start",
        "after_any_transition"
      )

      state_machine.reset!

      calls.clear

      state_machine.around_any_transition do |&do_it|
        do_it.call
        raise "kaboom"
      end

      expect {
        state_machine.start!
      }.to raise_error("kaboom")

      # 8 before, 8 around, and 8 error callbacks (we never make it to after because of the raise)
      expect(calls.size).to eq(24)
      expect(calls).to contain_exactly(
        "before_start_from_unexecuted_to_running",
        "before_transition_from_unexecuted_to_running",
        "before_start_from_unexecuted",
        "before_transition_from_unexecuted",
        "before_start_to_running",
        "before_transition_to_running",
        "before_start",
        "before_any_transition",
        "around_any_transition",
        "around_start",
        "around_transition_to_running",
        "around_start_to_running",
        "around_transition_from_unexecuted",
        "around_start_from_unexecuted",
        "around_transition_from_unexecuted_to_running",
        "around_start_from_unexecuted_to_running",
        "error_start_from_unexecuted_to_running",
        "error_transition_from_unexecuted_to_running",
        "error_start_from_unexecuted",
        "error_transition_from_unexecuted",
        "error_start_to_running",
        "error_transition_to_running",
        "error_start",
        "error_any_transition"
      )
    end
  end
end
