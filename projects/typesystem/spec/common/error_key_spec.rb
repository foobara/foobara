RSpec.describe Foobara::ErrorKey do
  let(:key) { described_class.new(category:, path:, runtime_path:, symbol:) }

  let(:category) { "some_category" }
  let(:path) { "some_path" }
  let(:runtime_path) { "some_runtime_path" }
  let(:symbol) { "some_symbol" }

  describe ".prepend_path" do
    subject { described_class.prepend_path(key, new_parts) }

    let(:new_parts) { [:path1, :path2] }

    context "when ErrorKey" do
      it { is_expected.to eq("some_runtime_path>some_category.path1.path2.some_path.some_symbol") }
    end

    context "when String" do
      let(:key) { super().to_s }

      it { is_expected.to eq("some_runtime_path>some_category.path1.path2.some_path.some_symbol") }
    end
  end

  describe ".prepend_runtime_path" do
    subject { described_class.prepend_runtime_path(key, new_parts) }

    let(:new_parts) { [:path1, :path2] }

    context "when ErrorKey" do
      it { is_expected.to eq("path1>path2>some_runtime_path>some_category.some_path.some_symbol") }
    end

    context "when String" do
      let(:key) { super().to_s }

      it { is_expected.to eq("path1>path2>some_runtime_path>some_category.some_path.some_symbol") }
    end
  end

  describe ".to_h" do
    subject { described_class.to_h(key) }

    let(:key) { "path1>path2>some_category.some_path.some_symbol" }
    let(:expected_hash) do
      {
        category: :some_category,
        runtime_path: [:path1, :path2],
        path: [:some_path],
        symbol: :some_symbol
      }
    end

    it { is_expected.to eq(expected_hash) }
  end
end
