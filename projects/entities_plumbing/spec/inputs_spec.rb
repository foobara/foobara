RSpec.describe Foobara::CommandPatternImplementation::Concerns::Entities do
  describe "#run" do
    after { Foobara.reset_alls }

    before do
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    end

    context "when passing entity type as the inputs" do
      let(:read_command) do
        user_class
        stub_class(:ReadUser, Foobara::Command) do
          inputs User
        end
      end

      context "when entity has no primary key yet" do
        let(:user_class) do
          stub_class :User, Foobara::Entity do
            attributes name: { type: :string, required: true }
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

      context "when entity has primary key" do
        let(:user_class) do
          stub_class :User, Foobara::Entity do
            attributes do
              name :string, :required
              id :integer
            end

            primary_key :id
          end
        end

        it "results in a MissingPrimaryKeyError" do
          expect {
            read_command
          }.to raise_error(Foobara::CommandPatternImplementation::BadCommandInputsError)
        end
      end
    end
  end
end
