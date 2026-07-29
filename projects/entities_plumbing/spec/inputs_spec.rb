RSpec.describe Foobara::CommandPatternImplementation::Concerns::Entities do
  describe "#run" do
    after { Foobara.reset_alls }

    before do
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    end

    let(:user_class) do
      stub_class :User, Foobara::Entity do
        attributes name: { type: :string, required: true }
      end
    end

    context "when passing entity type as the inputs" do
      let(:read_command) do
        user_class
        stub_class(:ReadUser, Foobara::Command) do
          inputs User
          # the above line should explode
        end
      end

      it "results in a MissingPrimaryKeyError" do
        expect {
          read_command
        }.to raise_error(
          Foobara::TypeDeclarations::Handlers::RegisteredTypeDeclaration::
              ValidatePrimaryKeyPresent::MissingPrimaryKeyError
        )
      end
    end
  end
end
