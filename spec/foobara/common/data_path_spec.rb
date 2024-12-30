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

    context "when path is empty string" do
      let(:path) { "" }
      let(:object) { 1 }

      it "returns the object itself" do
        expect(described_class.value_at(path, object)).to eq(object)
      end
    end
  end

  describe "#simple_collection?" do
    subject { described_class.new(path).simple_collection? }

    context "when not a collection" do
      let(:path) { %i[foo bar] }

      it { is_expected.to be(false) }
    end

    context "when not simple" do
      let(:path) { %i[foo # bar #] }

      it { is_expected.to be(false) }
    end

    context "when simple and a collection" do
      let(:path) { %i[foo bar baz #] }

      it { is_expected.to be(true) }
    end
  end

  describe ".set_value_at" do
    # rubocop:disable Style/OpenStructUse
    let(:object) do
      [
        {
          a: {
            b: [1, 2, { c: 4 }],
            d: OpenStruct.new
          }
        },
        "whatever"
      ]
    end

    context "when changing value of a hash" do
      let(:path) { [0, :a, :b, 2, :c] }

      it "can dig through the structure and set the value" do
        described_class.set_value_at(object, 100, path)

        expect(object).to eq(
          [
            {
              a: {
                b: [1, 2, { c: 100 }],
                d: OpenStruct.new
              }
            },
            "whatever"
          ]
        )
      end
    end

    context "when changing value of a hash indifferently" do
      let(:object) do
        {
          "a" => {
            "b" => 10
          }
        }
      end
      let(:path) { %w[a b] }

      it "can dig through the structure and set the value" do
        described_class.set_value_at(object, 100, path)

        expect(object).to eq("a" => { "b" => 100 })
      end
    end

    context "when changing an array element" do
      let(:path) { [0, :a, :b, 1] }

      it "can dig through the structure and set the value" do
        described_class.set_value_at(object, 100, path)

        expect(object).to eq(
          [
            {
              a: {
                b: [1, 100, { c: 4 }],
                d: OpenStruct.new
              }
            },
            "whatever"
          ]
        )
      end
    end

    context "when changing via method" do
      let(:path) { [0, :a, :d, :z] }

      it "can dig through the structure and set the value" do
        object[0][:a][:d].z = 15

        described_class.set_value_at(object, 200, path)

        expect(object).to eq(
          [
            {
              a: {
                b: [1, 2, { c: 4 }],
                d: OpenStruct.new(z: 200)
              }
            },
            "whatever"
          ]
        )
      end
    end
    # rubocop:enable Style/OpenStructUse
  end
end
