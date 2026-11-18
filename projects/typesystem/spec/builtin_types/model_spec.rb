RSpec.describe ":model type" do
  context "when it has a required attribute" do
    let(:capybara_class) do
      stub_class(:Capybara, Foobara::Model) do
        attributes do
          leg_count :integer, :required
        end
      end
    end

    context "when nothing is passed to .new" do
      let(:fumiko) { capybara_class.new }

      it "is not valid" do
        expect(fumiko).to_not be_valid
      end
    end

    context "when it has a default" do
      let(:capybara_class) do
        stub_class(:Capybara, Foobara::Model) do
          attributes do
            leg_count :integer, :required, default: 4
          end
        end
      end

      context "when nothing is passed to .new" do
        let(:fumiko) { capybara_class.new }

        it "applies the default" do
          expect(fumiko.leg_count).to eq(4)
        end

        it "is valid" do
          expect(fumiko).to be_valid
        end
      end
    end
  end
end
