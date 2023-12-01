RSpec.describe Foobara::DataPath do
  let(:key) { described_class.new(path) }

  let(:category) { "some_category" }
  let(:path) { "some_path" }
  let(:runtime_path) { "some_runtime_path" }
  let(:symbol) { "some_symbol" }

  describe ".prepend_path" do
    let(:new_parts) { %i[path1 path2] }

    context "when DataPath" do
      subject { described_class.prepend_path(key, new_parts) }

      it { is_expected.to eq(described_class.parse("path1.path2.some_path")) }
    end

    context "when string" do
      subject { described_class.prepend_path(path, new_parts) }

      it { is_expected.to eq(described_class.parse("path1.path2.some_path").to_s) }
    end
  end

  describe ".append_path" do
    let(:new_parts) { %i[path1 path2] }

    context "when DataPath" do
      subject { described_class.append_path(key, new_parts) }

      it { is_expected.to eq(described_class.parse("some_path.path1.path2")) }
    end

    context "when string" do
      subject { described_class.append_path(path, new_parts) }

      it { is_expected.to eq(described_class.parse("some_path.path1.path2").to_s) }
    end
  end

  describe ".to_s_type" do
    it "changes integer indices to pound sign" do
      expect(described_class.to_s_type("a.0.b")).to eq("a.#.b")
    end
  end

  describe "#to_sym" do
    it "just calls #to_sym on the string path" do
      expect(described_class.new(%i[a b]).to_sym).to eq(:"a.b")
    end
  end

  describe ".values_at" do
    subject { described_class.values_at(path, object) }

    context "when nested with two indices" do
      let(:path) { [:foo, :bar, :"#", :foo, :chars, 2] }

      let(:object) do
        Struct.new(:foo).new.tap do |o|
          o.foo = {
            bar: [
              {
                foo: "bar",
                foo2: "junk"
              },
              {
                foo: "baz"
              }
            ]
          }
        end
      end

      it { is_expected.to eq(%w[r z]) }

      context "when object has strings instead of symbols" do
        before do
          bar = object.foo.delete(:bar)
          expect(bar).to be_an(Array)

          object.foo["bar"] = bar
        end

        it { is_expected.to eq(%w[r z]) }
      end
    end
  end

  describe ".value_at" do
    let(:object) do
      Struct.new(:foo).new.tap do |o|
        o.foo = {
          bar: [
            {
              foo: "bar"
            }
          ]
        }
      end
    end

    let(:path) { [:foo, :bar, 0, :foo, :chars, 2] }
    let(:value) { described_class.value_at(path, object) }

    it "can find the relevant value" do
      expect(value).to eq("r")
    end

    context "when using strings in the path instead of symbols" do
      # Hmmmm... mildly surprising that this works with "2" instead of 2 but that's likely desirable.
      let(:path) { super().map(&:to_s) }

      it "can find the relevant value" do
        expect(value).to eq("r")
      end
    end

    context "when there's more than one value at the path" do
      let(:object) do
        Struct.new(:foo).new.tap do |o|
          o.foo = {
            bar: [
              {
                foo: "bar"
              },
              {
                foo: "baz"
              }
            ]
          }
        end
      end

      let(:path) { [:foo, :bar, :"#", :foo, :chars, 2] }

      it "raises TooManyValuesAtPathError" do
        expect { described_class.value_at(path, object) }.to raise_error(described_class::TooManyValuesAtPathError)
      end
    end
  end
end
