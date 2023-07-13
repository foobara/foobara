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
      let(:value) { "not a member of the enum" }

      it { is_expected_to_raise(Foobara::EnumeratedType::ValueNotAllowed) }
    end
  end

  describe ".enumerated_type_metadata" do
    it "gives the reflection information" do
      expect(klass.enumerated_type_metadata).to eq(
        some_enum: {
          allowed_values: %i[bar baz foo],
          constants_map: { "BAR" => :bar, "BAZ" => :baz, "FOO" => :foo },
          constants_module: EnumModule
        }
      )
    end
  end

  describe "automatic enumeration module discovery" do
    let(:klass) do
      Class.new do
        include Foobara::EnumeratedType

        enumerated :some_enum
      end
    end

    context "when at top-level with expected name" do
      before do
        stub_const("SomeEnum", EnumModule)
      end

      describe ".enumerated_type_metadata" do
        it "has the right module" do
          expect(klass.enumerated_type_metadata[:some_enum][:constants_module]).to eq(EnumModule)
        end
      end
    end

    context "when in class itself" do
      let(:klass) do
        Class.new do
          const_set("SomeEnum", EnumModule)

          include Foobara::EnumeratedType

          enumerated :some_enum
        end
      end

      describe ".enumerated_type_metadata" do
        it "has the right module" do
          expect(klass.enumerated_type_metadata[:some_enum][:constants_module]).to eq(EnumModule)
        end
      end
    end

    context "when in heirarchy" do
      let(:mod) do
        Module.new do
          const_set("SomeEnum", EnumModule)
        end
      end

      let(:klass) do
        Class.new do
          class << self
            def name
              "Mod::Klass"
            end
          end

          include Foobara::EnumeratedType

          enumerated :some_enum
        end
      end

      before do
        stub_const("Mod", mod)
      end

      describe ".enumerated_type_metadata" do
        it "has the right module" do
          expect(klass.enumerated_type_metadata[:some_enum][:constants_module]).to eq(EnumModule)
        end
      end
    end
  end
end
