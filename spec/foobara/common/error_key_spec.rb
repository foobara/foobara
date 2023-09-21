RSpec.describe Foobara::ErrorKey do
  let(:key) { described_class.new(category:, path:, runtime_path:, symbol:) }

  let(:category) { "some_category" }
  let(:path) { "some_path" }
  let(:runtime_path) { "some_runtime_path" }
  let(:symbol) { "some_symbol" }

  describe ".prepend_path" do
    let(:new_parts) { %i[path1 path2] }

    context "when ErrorKey" do
      subject { described_class.prepend_path(key, new_parts) }

      it { is_expected.to eq("some_runtime_path:some_category.path1.path2.some_path.some_symbol") }
    end
  end

  describe ".prepend_runtime_path" do
    let(:new_parts) { %i[path1 path2] }

    context "when ErrorKey" do
      subject { described_class.prepend_runtime_path(key, new_parts) }

      it { is_expected.to eq("path1:path2:some_runtime_path:some_category.some_path.some_symbol") }
    end
  end
end
