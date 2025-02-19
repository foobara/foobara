RSpec.describe ":string" do
  let(:type) { Foobara::BuiltinTypes[:string] }

  describe "#process!" do
    subject { type.process_value!(value) }

    context "when string" do
      let(:value) { "foo" }

      it { is_expected.to eq("foo") }
    end

    context "when symbol" do
      let(:value) { :foo }

      it { is_expected.to eq("foo") }
    end

    context "when not castable" do
      let(:value) { Object.new }

      it {
        is_expected_to_raise(
          Foobara::Value::Processor::Casting::CannotCastError,
          /Expected it to be a String, be a Numeric, or be a Symbol\z/
        )
      }
    end

    context "with transformers" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration(:string, :downcase)
      end

      context "when uppercase" do
        let(:value) { "FooBar" }

        it { is_expected.to eq("foobar") }
      end
    end

    context "with transformers and empty processor data" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration(:string, :downcase, {})
      end

      context "when uppercase" do
        let(:value) { "FooBar" }

        it { is_expected.to eq("foobar") }
      end
    end

    context "with validators" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration(:string, max_length: 10)
      end

      context "when too long" do
        let(:value) { "Foo Bar Baz" }

        it {
          is_expected_to_raise(
            Foobara::BuiltinTypes::String::SupportedValidators::MaxLength::MaxLengthExceededError,
            /\b10\b/
          ) { |error| expect(error.context[:max_length]).to eq(10) }
        }
      end
    end

    context "with :matches validator" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration(:string, matches: /bar/i)
      end

      context "when matches" do
        let(:value) { "Foo Bar" }

        it { is_expected.to eq(value) }
      end

      context "when does not match" do
        let(:value) { "Foo Baz" }

        it {
          is_expected_to_raise(
            Foobara::BuiltinTypes::String::SupportedValidators::Matches::DoesNotMatchError,
            /\/bar\/i\b/
          ) { |error| expect(error.context[:regex]).to eq(/bar/i.to_s) } # TODO: eliminate this .to_s call
        }
      end
    end

    context "with validators and transformers" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration(:string, :downcase, max_length: 10)
      end

      context "when uppercase" do
        let(:value) { "FooBar" }

        it { is_expected.to eq("foobar") }
      end

      context "when too long" do
        let(:value) { "Foo Bar Baz" }

        it {
          is_expected_to_raise(
            Foobara::BuiltinTypes::String::SupportedValidators::MaxLength::MaxLengthExceededError,
            /\b10\b/
          ) { |error| expect(error.context[:max_length]).to eq(10) }
        }
      end
    end
  end
end
