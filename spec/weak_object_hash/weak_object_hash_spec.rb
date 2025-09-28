RSpec.describe Foobara::WeakObjectHash do
  let(:weak_object_hash) { described_class.new }

  shared_examples "a weak object hash" do
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

    def self.setup_weak_object_hash
    end

    describe "#keys" do
      setup_weak_object_hash

      context "when a key is garbage collected" do
        it "does not include the garbage collected key" do
          @key1 = Object.new
          @key2 = Object.new
          @key3 = Object.new
          @value1 = Object.new
          @value2 = Object.new
          @value3 = Object.new

          weak_object_hash[@key1] = @value1
          weak_object_hash[@key2] = @value2
          weak_object_hash[@key3] = @value3

          expect(weak_object_hash.size).to eq(3)
          expect(
            weak_object_hash.keys.map(&:object_id)
          ).to eq([@key1, @key2, @key3].map(&:object_id))

          @key2 = nil
          GC.start

          expect(weak_object_hash.keys).to eq([@key1, @key3])
          expect(weak_object_hash.size).to eq(2)
        end
      end
    end

    describe "#values" do
      setup_weak_object_hash

      context "when a key is garbage collected" do
        it "does not include the garbage collected key" do
          @key1 = Object.new
          @key2 = Object.new
          @key3 = Object.new
          @value1 = Object.new
          @value2 = Object.new
          @value3 = Object.new

          weak_object_hash[@key1] = @value1
          weak_object_hash[@key2] = @value2
          weak_object_hash[@key3] = @value3

          expect(weak_object_hash.size).to eq(3)
          expect(weak_object_hash.values).to eq([@value1, @value2, @value3])

          @key2 = nil
          GC.start

          expect(weak_object_hash.values).to eq([@value1, @value3])
          expect(weak_object_hash.size).to eq(2)
        end
      end
    end
  end

  it_behaves_like "a weak object hash"

  context "when skipping finalizer" do
    before do
      weak_object_hash.skip_finalizer = true
    end

    it_behaves_like "a weak object hash"
  end
end
