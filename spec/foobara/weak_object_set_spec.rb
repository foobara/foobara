RSpec.describe Foobara::WeakObjectSet do
  let(:set) { described_class.new(key_method) }
  let(:some_object) { "asdf" }
  let(:some_object_id) { some_object.object_id }

  before do
    set << some_object
  end

  describe "auto-removal of garbage collected records" do
    let(:key_method) { nil }

    context "without key_method" do
      it "automatically removes records that have been garbage collected" do
        expect(set.include?(some_object_id)).to be(true)
        expect(set.include?(some_object)).to be(true)

        # NOTE: for whatever reason GC.start works for testing this in console but not in test suite.
        # So directly triggering the cleanup proc instead.
        set.garbage_cleaner.cleanup_proc.call(some_object_id)

        expect(set).to be_empty
      end
    end

    context "with key_method passed in" do
      let(:key_method) { :length }

      it "automatically removes records that have been garbage collected" do
        expect(set).to_not be_empty
        expect(set.size).to eq(1)
        expect(set.include_key?(4)).to be(true)
        expect(set.include?(some_object_id)).to be(true)

        expect(set.to_a).to eq(["asdf"])

        # NOTE: for whatever reason GC.start works for testing this in console but not in test suite.
        # So directly triggering the cleanup proc instead.
        set.garbage_cleaner.cleanup_proc.call(some_object_id)

        expect(set).to be_empty
        expect(set.size).to eq(0)
        expect(set.to_a).to eq([])
      end

      describe "#<<" do
        let(:some_class) do
          stub_class "Foo" do
            attr_accessor :bar
          end
        end
        let(:some_object) { some_class.new.tap { |o| o.bar = "asdf" } }
        let(:key_method) { :bar }

        context "when key is unset" do
          it "can no longer find the object by the old key" do
            expect(set.include_key?("asdf")).to be(true)

            some_object.bar = nil
            set << some_object

            # rubocop:disable RSpec/PredicateMatcher
            expect(set.include_key?("asdf")).to be_falsey
            # rubocop:enable RSpec/PredicateMatcher
            expect(set.include?(some_object)).to be(true)
            expect(set.include?(some_object_id)).to be(true)
          end
        end
      end
    end
  end
end
