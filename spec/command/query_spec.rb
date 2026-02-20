RSpec.describe Foobara::Query do
  before do
    stub_class(:SomeQuery, described_class) { def execute = "whatevs" }
  end

  it "contains is_query in its manifest" do
    expect(SomeQuery).to be_query
    expect(SomeQuery.foobara_manifest[:is_query]).to be(true)
  end
end
