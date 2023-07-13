RSpec.describe Foobara::EnumeratedType do
  let(:enum_module) do
    Module.new.tap do |m|
      m.const_set(:FOO, :foo)
      m.const_set(:BAR, :bar)
      m.const_set(:BAZ, :baz)
    end
  end
  let(:klass) do
    Class.new do
      include Foobara::EnumeratedType

      enumerated :some_enum, EnumModule
    end
  end
  let(:object) { klass.new }

  before do
    stub_const("EnumModule", enum_module)
  end

  describe "setter/getter" do
    subject {
      object.some_enum = value
      object.some_enum
    }

    context "when nil" do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end

    context "when valid symbol" do
      let(:value) { :bar }

      it { is_expected.to be :bar }
    end

    context "when valid string" do
      let(:value) { "bar" }

      it { is_expected.to be :bar }
    end

    context "when invalid value" do
      def is_expected_to_raise(error_class)
        expect { subject }.to raise_error(error_class)
      end

      let(:value) { "not a member of the enum" }

      it { is_expected_to_raise(Foobara::EnumeratedType::ValueNotAllowed) }
    end
  end
end
