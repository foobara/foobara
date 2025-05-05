RSpec.describe Foobara::WeakObjectSet do
  let(:set) { described_class.new(key_method) }

  describe "auto-removal of garbage collected records" do
    let(:key_method) { nil }

    context "without key_method" do
      it "automatically removes records that have been garbage collected" do
        some_object = "asdf"
        some_object_id = some_object.object_id
        set << some_object

        expect(set.include?(some_object_id)).to be(true)
        expect(set.include?(some_object)).to be(true)

        # rubocop:disable Lint/UselessAssignment
        some_object = nil
        # rubocop:enable Lint/UselessAssignment
        GC.start

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
        expect(set.include_key?("asdf")).to be(true)
        expect(set.include?(some_object_id)).to be(true)

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
