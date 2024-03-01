RSpec.describe Foobara::TypeDeclarations::TypedTransformer do
  describe ".type" do
    subject { transformer_class.type(from_type) }

    context "when .type_declaration is a type" do
      let(:from_type) { nil } # irrelevant for this type transformer but required
      let(:transformer_class) do
        stub_class :SomeTransformer, described_class do
          class << self
            def type_declaration(_from_type)
              Foobara::BuiltinTypes[:integer]
            end
          end
        end
      end

      it { is_expected.to eq(Foobara::BuiltinTypes[:integer]) }
    end
  end
end
