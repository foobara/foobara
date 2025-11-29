require "foobara/spec_helpers/it_behaves_like_a_crud_driver"

# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe Foobara::Persistence::CrudDrivers::InMemoryMinimal do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = described_class.new
  end

  it_behaves_like_a_crud_driver
end
# rubocop:enable RSpec/EmptyExampleGroup
