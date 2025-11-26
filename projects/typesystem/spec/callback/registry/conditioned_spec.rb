RSpec.describe Foobara::Callback::Registry::Conditioned do
  let(:registry) { described_class.new(charge: [:positive, :negative], mass: [:high, :low]) }

  describe "#register_callback" do
    let(:condition_key) { :charge }
    let(:condition_value) { :positive }
    let(:conditions) { { condition_key => condition_value } }

    def register_it
      registry.after(conditions) { "noop" }
    end

    context "when given good condition" do
      it "registers it and can return it even when unioned with other conditions" do
        expect {
          register_it
        }.to change { registry.callback_sets.size }.from(0).to(1)

        registry.unioned_callback_set_for(charge: :positive, mass: nil)
      end
    end

    context "when given bad condition key" do
      let(:condition_key) { :bad_key }

      it "explodes" do
        expect {
          register_it
        }.to raise_error(described_class::InvalidConditions)
      end
    end

    context "when given bad condition value" do
      let(:condition_value) { :bad_value }

      it "explodes" do
        expect {
          register_it
        }.to raise_error(described_class::InvalidConditions)
      end
    end

    context "when given nil value" do
      let(:condition_value) { nil }

      it "is fine" do
        expect {
          register_it
        }.to change { registry.callback_sets.size }.from(0).to(1)
      end
    end
  end

  describe "#runner" do
    context "when no conditions given" do
      let(:runner) { registry.runner.callback_data(foo: :bar) }

      describe "#run" do
        context "with block" do
          it "calls expected callbacks in order" do
            ran = false
            callback_ran = false

            registry.around do |foo:, &do_it|
              expect(foo).to eq(:bar)

              do_it.call

              callback_ran = true
            end

            expect {
              runner.run { ran = true }
            }.to change { ran }.from(false).to(true)

            expect(callback_ran).to be(true)
          end
        end

        context "with blocks" do
          let(:callbacks_ran) { [] }

          before do
            expect(registry).to_not have_before_callbacks
            expect(registry).to_not have_around_callbacks
            expect(registry).to_not have_after_callbacks
            expect(registry).to_not have_error_callbacks

            registry.before do |foo:|
              expect(foo).to eq(:bar)
              callbacks_ran << :before
            end

            expect(registry).to have_before_callbacks
            expect(registry).to_not have_around_callbacks
            expect(registry).to_not have_after_callbacks
            expect(registry).to_not have_error_callbacks

            registry.around do |foo:, &do_it|
              callbacks_ran << :around_start
              expect(foo).to eq(:bar)

              do_it.call

              callbacks_ran << :around_end
            end

            expect(registry).to have_before_callbacks
            expect(registry).to have_around_callbacks
            expect(registry).to_not have_after_callbacks
            expect(registry).to_not have_error_callbacks

            registry.after do |foo:|
              expect(foo).to eq(:bar)
              callbacks_ran << :after
            end

            expect(registry).to have_before_callbacks
            expect(registry).to have_around_callbacks
            expect(registry).to have_after_callbacks
            expect(registry).to_not have_error_callbacks

            registry.error do |error|
              expect(error).to be_a(Foobara::Callback::Runner::UnexpectedErrorWhileRunningCallback)
              expect(error.message).to eq("kaboom!")

              callbacks_ran << :error
            end

            expect(registry).to have_before_callbacks
            expect(registry).to have_around_callbacks
            expect(registry).to have_after_callbacks
            expect(registry).to have_error_callbacks
          end

          it "calls expected callbacks in order" do
            runner.run { "noop" }

            expect(callbacks_ran).to eq([:before, :around_start, :around_end, :after])
            callbacks_ran.clear

            expect {
              runner.run { raise "kaboom!" }
            }.to raise_error(RuntimeError)

            expect(callbacks_ran).to eq([:before, :around_start, :error])
          end
        end
      end
    end
  end
end
