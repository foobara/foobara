RSpec.describe Foobara::Callback::Registry::Conditioned do
  let(:registry) { described_class.new(charge: %i[positive negative], mass: %i[high low]) }

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
      end
    end
  end
end
