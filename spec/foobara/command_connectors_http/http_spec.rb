Foobara::Monorepo.project :command_connectors_http

RSpec.describe Foobara::CommandConnectors::Http do
  let(:command_class) do
    stub_class = ->(klass) { stub_const(klass.name, klass) }

    Class.new(Foobara::Command) do
      class << self
        def name
          "ComputeExponential"
        end
      end

      stub_class.call(self)

      inputs exponent: :integer,
             base: :integer

      attr_accessor :exponential

      def execute
        compute

        exponential
      end

      def compute
        self.exponential = 1

        exponent.times do
          self.exponential *= base
        end
      end
    end
  end

  let(:command_connector) do
    described_class.new
  end

  describe "#run_command", :focus do
    before do
      command_connector.connect(command_class)
    end

    let(:inputs) { { base: 2, exponent: 3 } }
    let(:outcome) { command_connector.run(command_class.name, inputs) }

    it "runs the command" do
      expect(outcome).to be_success
    end
  end
end
