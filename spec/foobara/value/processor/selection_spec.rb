RSpec.describe Foobara::Value::Processor::Selection do
  describe "#processor_for!" do
    subject { selection.processor_for!(value) }

    let(:processor_a) do
      Class.new(Foobara::Value::Processor) do
        class << self
          def name
            "ProcessorA"
          end
        end
        def applicable?(value)
          value == :a
        end
      end.instance
    end

    let(:processor_b) do
      Class.new(Foobara::Value::Processor) do
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

    context "when unique enforced" do
      let(:enforce_unique) { true }

      context "when it matches multiple processors" do
        let(:processors) { [processor_a, processor_a] }
        let(:value) { :a }

        it { is_expected_to_raise(described_class::MoreThanOneApplicableProcessorError) }
      end
    end

    context "when unique not enforced" do
      let(:enforce_unique) { false }

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
