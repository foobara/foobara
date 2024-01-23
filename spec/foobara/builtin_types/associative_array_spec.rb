RSpec.describe ":associative_array" do
  let(:type) { Foobara::BuiltinTypes[:associative_array] }

  describe "#process_value!" do
    subject { type.process_value!(value) }

    context "when array of pairs" do
      let(:value) { [[:a, 1], [:b, 2]] }

      it { is_expected.to eq(a: 1, b: 2) }
    end

    context "when hash" do
      let(:value) { { key1 => 1, key2 => 2 } }
      let(:key1) { Object.new }
      let(:key2) { Object.new }

      it { is_expected.to eq(key1 => 1, key2 => 2) }
    end

    context "when not castable" do
      let(:value) { Object.new }

      it {
        is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError,
                             /Expected it to be a Hash, or be a an array of pairs/)
      }
    end

    context "when there's a key_type_declaration" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration(
          :associative_array,
          key_type_declaration: :boolean
        )
      end

      describe "#types_depended_on" do
        it "includes the key type" do
          expect(type.types_depended_on.map(&:type_symbol)).to include(:boolean)
        end
      end

      describe "#possible_errors" do
        it "contains expected possible errors" do
          expect(type.possible_errors.to_h { |p| [p.key.to_sym, p.error_class] }).to eq(
            "data.#.key.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
            "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError
          )
        end
      end

      context "when keys adhere to type" do
        let(:value) do
          { y: 1, "FaLsE" => 2 }
        end

        it { is_expected.to eq(true => 1, false => 2) }
      end

      context "when keys do not adhere" do
        let(:outcome) { type.process_value(value) }
        let(:errors) { outcome.errors }

        let(:value) { { a: 1, b: 2 } }

        it "is not success" do
          expect(outcome).to_not be_success

          expect(errors.size).to eq(2)
          expect(errors.map(&:path)).to contain_exactly([0, :key], [1, :key])
          expect(errors).to all be_a(Foobara::Value::Processor::Casting::CannotCastError)
        end
      end
    end

    context "when there's a value_type_declaration" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration(
          :associative_array,
          value_type_declaration: :boolean
        )
      end

      describe "#possible_errors" do
        it "contains expected possible errors" do
          expect(type.possible_errors.to_h { |possible_error|
                   [possible_error.key.to_sym, possible_error.error_class]
                 }).to eq(
                   "data.#.value.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
                   "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError
                 )
        end
      end

      context "when values adhere to type" do
        let(:value) do
          { a: 1, b: "FalsE" }
        end

        it { is_expected.to eq(a: true, b: false) }
      end

      context "when values do not adhere" do
        let(:outcome) { type.process_value(value) }
        let(:errors) { outcome.errors }

        let(:value) { { a: :foo, b: 2 } }

        it "is not success" do
          expect(outcome).to_not be_success

          expect(errors.size).to eq(2)
          expect(errors.map(&:path)).to contain_exactly([0, :value], [1, :value])
          expect(errors).to all be_a(Foobara::Value::Processor::Casting::CannotCastError)
        end
      end
    end
  end

  describe "#cast!" do
    subject { type.cast!(value) }

    context "when not castable" do
      let(:value) { Object.new }

      it {
        is_expected_to_raise(Foobara::Value::Processor::Casting::CannotCastError,
                             /Expected it to be a Hash, or be a an array of pairs\z/)
      }
    end
  end
end
