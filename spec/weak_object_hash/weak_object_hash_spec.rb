RSpec.describe Foobara::WeakObjectHash do
  let(:weak_object_hash) { described_class.new }

  context "when finalizers in use" do
    before do
      weak_object_hash.skip_finalizer = false
    end

    describe "#[]" do
      it "gives back what is put in" do
        key = Object.new
        value = Object.new

        weak_object_hash[key] = value

        expect(weak_object_hash[key]).to be(value)
        expect(weak_object_hash.size).to eq(1)
        expect(weak_object_hash).to_not be_empty
      end

      context "when key is garbage collected" do
        it "gives nil" do
          key = Object.new
          value = Object.new

          weak_object_hash[key] = value

          expect(weak_object_hash[key]).to be(value)
          expect(weak_object_hash.size).to eq(1)
          expect(weak_object_hash).to_not be_empty

          key = nil
          GC.start

          expect(weak_object_hash[key]).to be_nil
          expect(weak_object_hash.size).to eq(0)
          expect(weak_object_hash).to be_empty
        end
      end
    end

    describe "#delete" do
      it "removes the entry" do
        key = Object.new
        value = Object.new

        weak_object_hash[key] = value

        expect(weak_object_hash[key]).to be(value)
        expect(weak_object_hash.size).to eq(1)
        expect(weak_object_hash).to_not be_empty

        expect(weak_object_hash.delete(key)).to eq(value)

        expect(weak_object_hash[key]).to be_nil
        expect(weak_object_hash.size).to eq(0)
        expect(weak_object_hash).to be_empty
      end
    end

    describe "#clear" do
      it "empties the hash" do
        key = Object.new
        value = Object.new

        weak_object_hash[key] = value

        expect(weak_object_hash[key]).to be(value)
        expect(weak_object_hash.size).to eq(1)
        expect(weak_object_hash).to_not be_empty

        weak_object_hash.clear

        expect(weak_object_hash[key]).to be_nil
        expect(weak_object_hash.size).to eq(0)
        expect(weak_object_hash).to be_empty
      end
    end

    describe "#close!" do
      it "closes the hash and gives errors when reading/writing to it" do
        key = Object.new
        value = Object.new

        weak_object_hash[key] = value

        expect(weak_object_hash[key]).to be(value)
        expect(weak_object_hash.size).to eq(1)
        expect(weak_object_hash).to_not be_empty
        expect(weak_object_hash).to_not be_closed

        weak_object_hash.close!

        expect {
          weak_object_hash[key] = value
        }.to raise_error(Foobara::WeakObjectHash::ClosedError)

        expect {
          weak_object_hash[key]
        }.to raise_error(Foobara::WeakObjectHash::ClosedError)

        expect {
          weak_object_hash.close!
        }.to raise_error(Foobara::WeakObjectHash::ClosedError)

        expect(weak_object_hash).to be_closed
      end
    end
  end

  context "when skipping finalizer" do
    before do
      weak_object_hash.skip_finalizer = true
    end

    describe "#[]" do
      it "gives back what is put in" do
        key = Object.new
        value = Object.new

        weak_object_hash[key] = value

        expect(weak_object_hash[key]).to be(value)
        expect(weak_object_hash.size).to eq(1)
        expect(weak_object_hash).to_not be_empty
      end
    end

    describe "#size" do
      context "when entry is garbage collected" do
        it "returns 0" do
          key = Object.new
          value = Object.new

          weak_object_hash[key] = value

          expect(weak_object_hash[key]).to be(value)
          expect(weak_object_hash.size).to eq(1)
          expect(weak_object_hash).to_not be_empty

          # rubocop:disable Lint/UselessAssignment
          key = nil
          # rubocop:enable Lint/UselessAssignment

          expect {
            GC.start
          }.to change(weak_object_hash, :size).from(1).to(0)
        end
      end
    end

    describe "#each_pair" do
      context "when entry is garbage collected" do
        it "becomes a noop like an empty hash" do
          key = Object.new
          value = Object.new

          weak_object_hash[key] = value

          pairs = []

          weak_object_hash.each_pair do |k, v|
            pairs << [k, v]
          end

          expect(pairs.size).to eq(1)

          # using object_id to prevent RSpec from holding a reference to these
          expect(pairs.first.map(&:object_id)).to eq([key.object_id, value.object_id])

          pairs = []
          # rubocop:disable Lint/UselessAssignment
          key = nil
          # rubocop:enable  Lint/UselessAssignment
          GC.start

          weak_object_hash.each_pair { |k, v| pairs << [k, v] }

          expect(pairs).to be_empty
        end
      end
    end

    describe "#delete" do
      it "removes the entry" do
        key = Object.new
        value = Object.new

        weak_object_hash[key] = value

        expect(weak_object_hash[key]).to be(value)
        expect(weak_object_hash.size).to eq(1)
        expect(weak_object_hash).to_not be_empty

        expect(weak_object_hash.delete(key)).to eq(value)

        expect(weak_object_hash[key]).to be_nil
        expect(weak_object_hash.size).to eq(0)
        expect(weak_object_hash).to be_empty
      end
    end

    describe "#clear" do
      it "empties the hash" do
        key = Object.new
        value = Object.new

        weak_object_hash[key] = value

        expect(weak_object_hash[key]).to be(value)
        expect(weak_object_hash.size).to eq(1)
        expect(weak_object_hash).to_not be_empty

        weak_object_hash.clear

        expect(weak_object_hash[key]).to be_nil
        expect(weak_object_hash.size).to eq(0)
        expect(weak_object_hash).to be_empty
      end
    end

    describe "#close!" do
      it "closes the hash and gives errors when reading/writing to it" do
        key = Object.new
        value = Object.new

        weak_object_hash[key] = value

        expect(weak_object_hash[key]).to be(value)
        expect(weak_object_hash.size).to eq(1)
        expect(weak_object_hash).to_not be_empty
        expect(weak_object_hash).to_not be_closed

        weak_object_hash.close!

        expect {
          weak_object_hash[key] = value
        }.to raise_error(Foobara::WeakObjectHash::ClosedError)

        expect {
          weak_object_hash[key]
        }.to raise_error(Foobara::WeakObjectHash::ClosedError)

        expect {
          weak_object_hash.close!
        }.to raise_error(Foobara::WeakObjectHash::ClosedError)

        expect(weak_object_hash).to be_closed
      end
    end
  end
end
