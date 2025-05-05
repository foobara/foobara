RSpec.describe Foobara::DetachedEntity do
  after { Foobara.reset_alls }

  let(:detached_entity_class) do
    stub_class("SomeDetachedEntity", described_class) do
      attributes do
        id :integer, :required
        foo :string, :required
      end

      primary_key :id
    end
  end

  context "when casting from a primary key" do
    it "results in an unloaded DetachedEntity" do
      outcome = detached_entity_class.model_type.process_value(5)
      expect(outcome).to be_success

      result = outcome.result

      expect(result).to be_a(described_class)

      expect(result).to_not be_loaded
      expect(result.id).to eq(5)
      expect {
        result.foo
      }.to raise_error(described_class::CannotReadAttributeOnUnloadedRecordError)
    end
  end
end
