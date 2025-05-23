RSpec.describe Foobara::Value::Processor::Selection do
  describe "#processor_for!" do
    subject { selection.processor_for!(value) }

    let(:processor_a) do
      stub_class "ProcessorA", Foobara::Value::Processor do
        def applicable?(value)
          value == :a
        end
      end.instance
    end

    let(:processor_b) do
      stub_class "ProcessorB", Foobara::Value::Processor do
        class << self
          def name
            "ProcessorB"
          end
        end
        def applicable?(value)
          value == :b
        end
      end.instance
    end

    let(:processors) { [processor_a, processor_b] }

    let(:selection) do
      described_class.new(processors:, enforce_unique:)
    end
    let(:enforce_unique) { false }

    context "when wanting nil when no processor matches" do
      let(:error_if_none_applicable) { false }
      let(:selection) do
        described_class.new(processors:, enforce_unique:, error_if_none_applicable:)
      end

      context "when it does not match a processor" do
        let(:value) { :c }

        it { is_expected.to be_nil }
      end
    end

    context "when unique enforced" do
      let(:enforce_unique) { true }

      context "when it matches multiple processors" do
        let(:processors) { [processor_a, processor_a] }
        let(:value) { :a }

        it { is_expected_to_raise(described_class::MoreThanOneApplicableProcessorError) }
      end
    end

    context "when unique not enforced" do
      context "when it matches a processor" do
        let(:value) { :a }

        it { is_expected.to be(processor_a) }
      end

      context "when it does not match a processor" do
        let(:value) { :c }

        it { is_expected_to_raise(described_class::NoApplicableProcessorError) }
      end
    end
  end
end
