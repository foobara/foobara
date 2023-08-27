RSpec.describe Foobara::Callback::Registry::MultipleAction do
  let(:registry) { described_class.new(:run, :walk) }

  describe "#register_callback" do
    let(:action) { :run }

    def register_it
      registry.after(action) { "noop" }
    end

    context "when given good action" do
      it "registers it and can return it even when unioned with other actions" do
        expect {
          register_it
        }.to change { registry.callback_sets.size }.from(0).to(1)

        set = registry.unioned_callback_set_for(:run)
        expect(set.size).to eq(1)
        set = registry.unioned_callback_set_for(nil)
        expect(set.size).to eq(1)
        set = registry.unioned_callback_set_for(:walk)
        expect(set.size).to eq(0)
        expect {
          registry.unioned_callback_set_for(:bad_symbol)
        }.to raise_error(described_class::InvalidAction)
      end
    end

    context "when given bad action" do
      let(:action) { :bad_key }

      it "explodes" do
        expect {
          register_it
        }.to raise_error(described_class::InvalidAction)
      end
    end

    context "when given nil value" do
      let(:action) { nil }

      it "is fine" do
        expect {
          register_it
        }.to change { registry.callback_sets.size }.from(0).to(1)
      end
    end
  end

  describe "#runner" do
    context "when no action given" do
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

            expect(callbacks_ran).to eq(%i[before around_start around_end after])
            callbacks_ran.clear

            expect {
              runner.run { raise "kaboom!" }
            }.to raise_error(RuntimeError)

            expect(callbacks_ran).to eq(%i[before around_start error])
          end
        end
      end
    end
  end
end
