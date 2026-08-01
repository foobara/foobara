RSpec.describe Foobara::CommandPatternImplementation::Concerns::Reflection do
  after do
    Foobara.reset_alls
  end

  describe "#types_depended_on" do
    context "when command has no types at all" do
      subject { command_class.types_depended_on }

      let(:command_class) { stub_class(:CommandClass, Foobara::Command) }

      it { is_expected.to be_empty }
      it { is_expected.to be(command_class.types_depended_on) }
    end
  end
end
