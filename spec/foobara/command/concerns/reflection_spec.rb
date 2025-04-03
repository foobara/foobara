RSpec.describe Foobara::CommandPatternImplementation::Concerns::Reflection do
  after do
    Foobara.reset_alls
  end

  describe "#types_depended_on" do
    context "when command has no types at all" do
      subject { stub_class(:CommandClass, Foobara::Command).types_depended_on }

      it { is_expected.to be_empty }
    end
  end
end
