RSpec.describe Foobara::WeakObjectSet do
  after { set.close }

  let(:set) { described_class.new(key_method) }
  let(:key_method) { nil }

  describe "auto-removal of garbage collected records" do
    context "without key_method" do
      it "automatically removes records that have been garbage collected" do
        some_object = "asdf"
        set << some_object

        # Deleting this line breaks the spec for mysterious reasons. Without this line, GC.start doesn't
        # call the finalizer for "asdf" for some reason until the end of the test suite.
        # It looks like when these finalizers run is not guaranteed so it might be a bad idea to
        # test the behavior as if it were. Will leave this test here for now but might need to delete it if
        # it acts up in other environments.
        expect(set.size).to eq(1)

        # rubocop:disable Lint/UselessAssignment
        some_object = nil
        # rubocop:enable Lint/UselessAssignment
        GC.start

        expect(set.size).to eq(0)
        expect(set).to be_empty
      end
    end

    context "with key_method passed in" do
      let(:some_class) do
        stub_class "Foo" do
          attr_accessor :bar
        end
      end
      let(:key_method) { :bar }

      it "automatically removes records that have been garbage collected" do
        some_object = some_class.new.tap { |o| o.bar = "asdf" }
        some_object_id = some_object.object_id
        set << some_object

        expect(set).to_not be_empty
        expect(set.size).to eq(1)
        expect(set.find_by_key("asdf").object_id).to eq(some_object.object_id)
        expect(set[some_object_id].object_id).to be(some_object.object_id)

        expect(set.to_a.map(&:object_id)).to eq([some_object_id])

        # rubocop:disable Lint/UselessAssignment
        some_object = nil
        # rubocop:enable Lint/UselessAssignment
        GC.start

        expect(set).to be_empty
        expect(set.size).to eq(0)
        expect(set.to_a).to eq([])
      end

      describe "#<<" do
        context "when key is unset" do
          it "can no longer find the object by the old key" do
            some_object = some_class.new.tap { |o| o.bar = "asdf" }
            some_object_id = some_object.object_id
            set << some_object

            expect(set.find_by_key("asdf").object_id).to eq(some_object.object_id)

            some_object.bar = nil
            set << some_object

            expect(set.find_by_key("asdf")).to be_nil
            expect(set[some_object]).to eq(some_object)
            expect(set[some_object_id]).to eq(some_object)
          end
        end
      end
    end
  end

  describe "#delete" do
    it "removes the object being deleted" do
      some_object = "asdf"
      set << some_object

      expect {
        set.delete(some_object)
      }.to change { set.member?(some_object) }.from(true).to(false)
    end
  end
end
