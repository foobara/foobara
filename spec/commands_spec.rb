# frozen_string_literal: true

RSpec.describe Commands do
  it "has a version number" do
    expect(Commands::VERSION).not_to be nil
  end
end
