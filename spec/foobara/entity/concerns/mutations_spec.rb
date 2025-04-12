RSpec.describe Foobara::Entity::Concerns::Mutations do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:capybara_class) do
    stub_class "Capybara", Foobara::Entity do
      attributes do
        id :integer
        name :string, :required
        age :integer, :required
      end

      primary_key :id
    end
  end

  describe "#update" do
    it "updates the record in a persistent way" do
      capybara = capybara_class.transaction do
        Capybara.create(name: "Basil", age: 100)
      end

      expect {
        Capybara.transaction do
          record = Capybara.load(capybara.id)
          record.update(age: 101)
        end
      }.to change {
        Capybara.transaction { Capybara.load(capybara.id).age }
      }.from(100).to(101)
    end
  end
end
