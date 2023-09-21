RSpec.describe Foobara::WeakObjectSet do
  let(:set) { described_class.new(key_method) }

  describe "auto-removal of garbage collected records" do
    let(:key_method) { nil }

    context "without key_method" do
      it "automatically removes records that have been garbage collected" do
        s = "asdf"
        object_id = s.object_id
        set << s

        expect(set.include?(object_id)).to be(true)
        expect(set.include?(s)).to be(true)

        # NOTE: for whatever reason GC.start works for testing this in console but not in test suite.
        # So directly trigging the cleanup proc instead.
        set.garbage_cleaner.cleanup_proc.call(object_id)

        expect(set).to be_empty
      end
    end

    context "with key_method passed in" do
      let(:key_method) { :length }

      it "automatically removes records that have been garbage collected" do
        s = "asdf"
        object_id = s.object_id
        set << s

        expect(set).to_not be_empty
        expect(set.size).to eq(1)
        expect(set.include_key?(4)).to be(true)
        expect(set.include?(object_id)).to be(true)

        expect(set.to_a).to eq(["asdf"])

        # NOTE: for whatever reason GC.start works for testing this in console but not in test suite.
        # So directly trigging the cleanup proc instead.
        set.garbage_cleaner.cleanup_proc.call(object_id)

        expect(set).to be_empty
        expect(set.size).to eq(0)
        expect(set.to_a).to eq([])
      end
    end
  end
end
