RSpec.describe Foobara::TruncatedInspect do
  let(:object) do
    f = foo

    Object.new.tap do |o|
      o.instance_eval do
        @foo = f
      end
    end
  end

  let(:foo) do
    "bar"
  end

  before do
    object.extend(described_class)
  end

  describe "#inspect" do
    subject { object.inspect }

    it { is_expected.to match(/foo="bar"/) }

    context "when foo is an array" do
      let(:foo) { [1, 2, 3] }

      it { is_expected.to match(/foo=\[1, 2, 3\]/) }

      context "when foo is too long" do
        let(:foo) { [1] * 100 }

        it { is_expected.to match(/foo=\[\.\.\.\]/) }
      end
    end

    context "when foo is a hash" do
      let(:foo) { { a: 1, b: 2, c: 3 } }

      it { is_expected.to match(/foo=\{:a=>1, :b=>2, :c=>3\}/) }

      context "when foo is too long" do
        let(:foo) do
          (0..100).to_h do |i|
            [i.to_s, i]
          end
        end

        it { is_expected.to match(/foo=\{\.\.\.\}/) }
      end
    end

    context "when there's too many instance variables" do
      before do
        ("a".."z").to_a.each do |c1|
          ("A".."Z").to_a.each do |c2|
            object.instance_variable_set("@#{c1}#{c2}", "baz")
          end
        end
      end

      it "has the maximum length" do
        expect(object.inspect.length).to eq(described_class::MAX_LENGTH)
      end
    end

    context "when circular reference" do
      let(:object) do
        dc = described_class

        Object.new.tap do |o|
          o.instance_eval do
            @me = self
            @other = Object.new.tap { |other| other.extend(dc) }
          end
        end
      end

      it "can still truncate" do
        expect(object.inspect).to match(/@me=.../)
      end
    end
  end
end
